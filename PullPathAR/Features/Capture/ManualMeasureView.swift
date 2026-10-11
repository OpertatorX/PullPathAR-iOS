import SwiftUI
import SwiftData
import UIKit

private struct ManualSegmentDraft: Identifiable {
    let id = UUID()
    var length: Double
}

struct ManualMeasureView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RoutePoint.orderIndex) private var allPoints: [RoutePoint]
    let route: CableRoute
    @State private var segments: [ManualSegmentDraft] = [ManualSegmentDraft(length: 0)]
    @State private var loadedExisting = false

    private var routePoints: [RoutePoint] {
        allPoints.filter { $0.routeID == route.id }.sorted { $0.orderIndex < $1.orderIndex }
    }

    private var enteredTotalMeters: Double {
        segments.reduce(0) { result, segment in
            result + meters(fromDisplayedValue: max(0, segment.length))
        }
    }

    private var unitSuffix: String {
        route.unitSystem == .metric ? "m" : "ft"
    }

    var body: some View {
        Form {
            Section {
                Text("manual.description")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section("manual.segments") {
                ForEach($segments) { $segment in
                    HStack {
                        Text("\(String(localized: "manual.segment")) \(segmentIndex(for: segment.id) + 1)")
                        Spacer()
                        TextField("0", value: $segment.length, format: .number.precision(.fractionLength(0...2)))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(minWidth: 80, maxWidth: 130)
                        Text(unitSuffix)
                            .foregroundStyle(.secondary)
                    }
                }
                .onDelete { offsets in
                    segments.remove(atOffsets: offsets)
                    if segments.isEmpty {
                        segments.append(ManualSegmentDraft(length: 0))
                    }
                }

                Button {
                    segments.append(ManualSegmentDraft(length: 0))
                } label: {
                    Label("manual.add.segment", systemImage: "plus")
                }
            }

            Section("manual.summary") {
                LabeledContent(
                    "manual.measured",
                    value: RouteMath.formattedLength(meters: enteredTotalMeters, unitSystem: route.unitSystem)
                )
                LabeledContent(
                    "manual.required",
                    value: RouteMath.formattedLength(
                        meters: RouteMath.requiredLength(
                            baseMeters: enteredTotalMeters,
                            fixedSlackMeters: route.fixedSlackMeters,
                            slackPercent: route.slackPercent
                        ),
                        unitSystem: route.unitSystem
                    )
                )
            }
        }
        .navigationTitle("manual.title")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("common.save") {
                    saveMeasurement()
                    dismiss()
                }
                .disabled(segments.allSatisfy { $0.length <= 0 })
            }
        }
        .onAppear(perform: loadExistingSegmentsOnce)
    }

    private func segmentIndex(for id: UUID) -> Int {
        segments.firstIndex(where: { $0.id == id }) ?? 0
    }

    private func displayedValue(fromMeters meters: Double) -> Double {
        route.unitSystem == .metric ? meters : RouteMath.metersToFeet(meters)
    }

    private func meters(fromDisplayedValue value: Double) -> Double {
        route.unitSystem == .metric ? value : RouteMath.feetToMeters(value)
    }

    private func loadExistingSegmentsOnce() {
        guard !loadedExisting else { return }
        loadedExisting = true
        let lengths = RouteMath.segmentLengths(points: RouteMath.vectors(from: routePoints))
        if !lengths.isEmpty {
            segments = lengths.map { ManualSegmentDraft(length: displayedValue(fromMeters: $0)) }
        }
    }

    private func saveMeasurement() {
        for point in routePoints {
            modelContext.delete(point)
        }

        var cumulativeMeters = 0.0
        modelContext.insert(
            RoutePoint(
                routeID: route.id,
                orderIndex: 0,
                xMeters: 0,
                yMeters: 0,
                zMeters: 0,
                source: .manual,
                label: "P1"
            )
        )

        for (index, segment) in segments.enumerated() {
            let lengthMeters = meters(fromDisplayedValue: max(0, segment.length))
            guard lengthMeters > 0 else { continue }
            cumulativeMeters += lengthMeters
            modelContext.insert(
                RoutePoint(
                    routeID: route.id,
                    orderIndex: index + 1,
                    xMeters: cumulativeMeters,
                    yMeters: 0,
                    zMeters: 0,
                    source: .manual,
                    label: "P\(index + 2)"
                )
            )
        }

        route.updatedAt = .now
        modelContext.insert(
            HistoryEntry(
                routeID: route.id,
                kind: .measured,
                detail: "Manual • \(RouteMath.formattedLength(meters: cumulativeMeters, unitSystem: route.unitSystem))"
            )
        )
        try? modelContext.save()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
