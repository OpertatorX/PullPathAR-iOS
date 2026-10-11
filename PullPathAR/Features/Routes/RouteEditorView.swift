import SwiftUI
import SwiftData

struct RouteEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var route: CableRoute
    @Query(sort: \RoutePoint.orderIndex) private var allPoints: [RoutePoint]

    private var routePoints: [RoutePoint] {
        allPoints.filter { $0.routeID == route.id }.sorted { $0.orderIndex < $1.orderIndex }
    }

    var body: some View {
        Form {
            Section("route.editor.details") {
                TextField("routes.name", text: $route.name)
                Picker("route.status", selection: $route.statusRaw) {
                    ForEach(RouteStatus.allCases) { status in
                        Text(status.localizedTitle).tag(status.rawValue)
                    }
                }
                Picker("settings.units", selection: $route.unitSystemRaw) {
                    Text("units.metric").tag(UnitSystem.metric.rawValue)
                    Text("units.imperial").tag(UnitSystem.imperial.rawValue)
                }
            }

            Section("route.editor.slack") {
                LabeledContent("route.slack.fixed") {
                    TextField(
                        "0",
                        value: $route.fixedSlackMeters,
                        format: .number.precision(.fractionLength(0...2))
                    )
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                }
                LabeledContent("route.slack.percent") {
                    TextField(
                        "0",
                        value: $route.slackPercent,
                        format: .number.precision(.fractionLength(0...1))
                    )
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                }
            }

            Section("route.editor.points") {
                if routePoints.isEmpty {
                    Text("route.points.empty")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(routePoints) { point in
                        NavigationLink {
                            RoutePointEditorView(point: point)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(point.label.isEmpty ? "P\(point.orderIndex + 1)" : point.label)
                                        .font(.headline)
                                    Text(point.source == .augmentedReality ? LocalizedStringKey("route.point.ar") : LocalizedStringKey("route.point.manual"))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(coordinateSummary(point))
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                    .onDelete(perform: deletePoints)
                    .onMove(perform: movePoints)
                }
            }

            Section("common.notes") {
                TextField("common.notes.optional", text: $route.notes, axis: .vertical)
                    .lineLimit(4...10)
            }
        }
        .navigationTitle("route.editor.title")
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.editMode, .constant(.active))
        .onChange(of: route.statusRaw) { oldValue, newValue in
            guard oldValue != newValue else { return }
            route.updatedAt = .now
            modelContext.insert(
                HistoryEntry(
                    routeID: route.id,
                    kind: .statusChanged,
                    detail: newValue
                )
            )
            try? modelContext.save()
        }
        .onDisappear {
            route.fixedSlackMeters = max(0, route.fixedSlackMeters)
            route.slackPercent = max(0, route.slackPercent)
            route.updatedAt = .now
            try? modelContext.save()
        }
    }

    private func coordinateSummary(_ point: RoutePoint) -> String {
        String(format: "%.2f, %.2f, %.2f", point.xMeters, point.yMeters, point.zMeters)
    }

    private func deletePoints(at offsets: IndexSet) {
        let current = routePoints
        for index in offsets {
            modelContext.delete(current[index])
        }
        normalizePointOrder()
        route.updatedAt = .now
        try? modelContext.save()
    }

    private func movePoints(from source: IndexSet, to destination: Int) {
        var reordered = routePoints
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, point) in reordered.enumerated() {
            point.orderIndex = index
        }
        route.updatedAt = .now
        try? modelContext.save()
    }

    private func normalizePointOrder() {
        let remaining = routePoints
        for (index, point) in remaining.enumerated() {
            point.orderIndex = index
        }
    }
}

private struct RoutePointEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var point: RoutePoint

    var body: some View {
        Form {
            Section("route.point.identity") {
                TextField("route.point.label", text: $point.label)
                LabeledContent(
                    "route.point.source",
                    value: point.source == .augmentedReality
                        ? String(localized: "route.point.ar")
                        : String(localized: "route.point.manual")
                )
            }

            Section("route.point.coordinates") {
                coordinateField("X", value: $point.xMeters)
                coordinateField("Y", value: $point.yMeters)
                coordinateField("Z", value: $point.zMeters)
                Text("route.point.coordinates.hint")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(point.label.isEmpty ? "route.point.title" : point.label)
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { try? modelContext.save() }
    }

    @ViewBuilder
    private func coordinateField(_ axis: String, value: Binding<Double>) -> some View {
        LabeledContent(axis) {
            TextField(axis, value: value, format: .number.precision(.fractionLength(0...3)))
                .keyboardType(.numbersAndPunctuation)
                .multilineTextAlignment(.trailing)
        }
    }
}
