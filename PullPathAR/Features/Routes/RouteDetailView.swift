import SwiftUI
import SwiftData
import ARKit

struct RouteDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var route: CableRoute
    let project: Project

    @Query(sort: \RoutePoint.orderIndex) private var allPoints: [RoutePoint]
    @Query(sort: \CableProfile.name) private var profiles: [CableProfile]
    @Query(sort: \CableReel.updatedAt, order: .reverse) private var reels: [CableReel]
    @Query(sort: \PhotoNote.createdAt, order: .reverse) private var allPhotos: [PhotoNote]
    @Query(sort: \HistoryEntry.timestamp, order: .reverse) private var allHistory: [HistoryEntry]

    @State private var exportURL: URL?
    @State private var presentingShare = false
    @State private var exportError = false

    private var routePoints: [RoutePoint] {
        allPoints.filter { $0.routeID == route.id }.sorted { $0.orderIndex < $1.orderIndex }
    }

    private var photos: [PhotoNote] {
        allPhotos.filter { $0.routeID == route.id }
    }

    private var history: [HistoryEntry] {
        allHistory.filter { $0.routeID == route.id }
    }

    private var cableProfile: CableProfile? {
        guard let id = route.profileID else { return nil }
        return profiles.first { $0.id == id }
    }

    private var assignedReel: CableReel? {
        guard let id = route.assignedReelID else { return nil }
        return reels.first { $0.id == id }
    }

    private var measuredMeters: Double {
        RouteMath.totalLength(points: RouteMath.vectors(from: routePoints))
    }

    private var slackMeters: Double {
        RouteMath.slackLength(
            baseMeters: measuredMeters,
            fixedMeters: route.fixedSlackMeters,
            percent: route.slackPercent
        )
    }

    private var requiredMeters: Double {
        RouteMath.requiredLength(
            baseMeters: measuredMeters,
            fixedSlackMeters: route.fixedSlackMeters,
            slackPercent: route.slackPercent
        )
    }

    private var hasARGeometry: Bool {
        routePoints.count > 1 && routePoints.contains { $0.source == .augmentedReality }
    }

    private var geometry: RouteGeometrySummary {
        RouteMath.geometrySummary(points: RouteMath.vectors(from: routePoints))
    }

    var body: some View {
        List {
            Section {
                RouteMeasureSummary(
                    route: route,
                    measuredMeters: measuredMeters,
                    slackMeters: slackMeters,
                    requiredMeters: requiredMeters,
                    assignedReel: assignedReel
                )
            }
            .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))

            Section("route.measure.section") {
                if ARWorldTrackingConfiguration.isSupported {
                    NavigationLink {
                        ARCaptureScreen(route: route)
                    } label: {
                        Label("route.measure.ar", systemImage: "camera.viewfinder")
                    }
                } else {
                    LabeledContent("route.measure.ar", value: String(localized: "route.measure.ar.unavailable"))
                }

                NavigationLink {
                    ManualMeasureView(route: route)
                } label: {
                    Label("route.measure.manual", systemImage: "ruler")
                }

                NavigationLink {
                    RouteEditorView(route: route)
                } label: {
                    Label("route.editor.title", systemImage: "slider.horizontal.3")
                }
            }

            if hasARGeometry {
                Section("route.geometry.section") {
                    LabeledContent(
                        "route.geometry.horizontal",
                        value: RouteMath.formattedLength(meters: geometry.horizontalTravelMeters, unitSystem: route.unitSystem)
                    )
                    LabeledContent(
                        "route.geometry.vertical",
                        value: RouteMath.formattedLength(meters: geometry.verticalTravelMeters, unitSystem: route.unitSystem)
                    )
                    LabeledContent(
                        "route.geometry.elevation",
                        value: RouteMath.formattedLength(meters: geometry.elevationRangeMeters, unitSystem: route.unitSystem)
                    )
                    LabeledContent(
                        "route.geometry.direct",
                        value: RouteMath.formattedLength(meters: geometry.straightLineMeters, unitSystem: route.unitSystem)
                    )
                }
            }

            Section("route.material.section") {
                NavigationLink {
                    CableProfileAssignmentView(route: route)
                } label: {
                    LabeledContent(
                        "profiles.profile",
                        value: cableProfile?.name ?? String(localized: "profiles.none")
                    )
                }

                NavigationLink {
                    ReelAllocationView(route: route, requiredMeters: requiredMeters)
                } label: {
                    LabeledContent(
                        "route.reel",
                        value: assignedReel?.name ?? String(localized: "route.reel.none")
                    )
                }
            }

            Section("route.documentation.section") {
                NavigationLink {
                    RoutePhotosView(route: route)
                } label: {
                    LabeledContent("photos.title", value: "\(photos.count)")
                }

                Button {
                    exportPullSheet()
                } label: {
                    Label("route.export.pdf", systemImage: "square.and.arrow.up")
                }
                .disabled(routePoints.count < 2)
            }

            if !history.isEmpty {
                Section("route.history.section") {
                    ForEach(history.prefix(8)) { entry in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: entry.kind.symbolName)
                                .foregroundStyle(.secondary)
                                .frame(width: 20)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(entry.kind.localizedTitle)
                                    .font(.subheadline.weight(.medium))
                                if !entry.detail.isEmpty {
                                    Text(entry.detail)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Text(entry.timestamp, style: .relative)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(route.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $presentingShare) {
            if let exportURL {
                ShareSheet(items: [exportURL])
            }
        }
        .alert("route.export.error.title", isPresented: $exportError) {
            Button("common.ok", role: .cancel) { }
        } message: {
            Text("route.export.error.message")
        }
    }

    private func exportPullSheet() {
        let vectors = RouteMath.vectors(from: routePoints)
        let lengths = RouteMath.segmentLengths(points: vectors)
        let segments = lengths.enumerated().map { index, length in
            PullSheetSegment(
                index: index + 1,
                fromLabel: routePoints[index].label,
                toLabel: routePoints[index + 1].label,
                lengthMeters: length
            )
        }

        let postPullRemaining: Double?
        if let assignedReel {
            let assessment = RouteMath.reelAssessment(
                requiredMeters: requiredMeters,
                availableMeters: assignedReel.remainingLengthMeters
            )
            postPullRemaining = assessment.fits ? assessment.remainingMeters : nil
        } else {
            postPullRemaining = nil
        }

        let snapshot = PullSheetSnapshot(
            projectName: project.name,
            clientName: project.clientName,
            siteName: project.siteName,
            routeName: route.name,
            cableProfileName: cableProfile?.name ?? String(localized: "profiles.none"),
            routeStatus: route.status.localizedString,
            baseLengthMeters: measuredMeters,
            fixedSlackMeters: route.fixedSlackMeters,
            slackPercent: route.slackPercent,
            requiredLengthMeters: requiredMeters,
            reelName: assignedReel?.name ?? "",
            reelRemainingMeters: postPullRemaining,
            notes: route.notes,
            segments: segments,
            generatedAt: .now
        )

        let data = PullSheetPDFService.render(snapshot: snapshot, unitSystem: route.unitSystem)
        let safeName = route.name
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("PullPath-\(safeName).pdf")

        do {
            try data.write(to: url, options: .atomic)
            exportURL = url
            modelContext.insert(
                HistoryEntry(routeID: route.id, kind: .exported, detail: url.lastPathComponent)
            )
            route.updatedAt = .now
            try? modelContext.save()
            presentingShare = true
        } catch {
            exportError = true
        }
    }
}

private struct RouteMeasureSummary: View {
    let route: CableRoute
    let measuredMeters: Double
    let slackMeters: Double
    let requiredMeters: Double
    let assignedReel: CableReel?

    private var assessment: ReelAssessment? {
        guard let assignedReel else { return nil }
        return RouteMath.reelAssessment(
            requiredMeters: requiredMeters,
            availableMeters: assignedReel.remainingLengthMeters
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("route.required")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(RouteMath.formattedLength(meters: requiredMeters, unitSystem: route.unitSystem))
                        .font(.system(.title, design: .rounded, weight: .bold).monospacedDigit())
                }
                Spacer()
                Label(route.status.localizedTitle, systemImage: route.status.symbolName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(route.status.tint)
            }

            HStack(spacing: 24) {
                metric("route.measured", meters: measuredMeters)
                metric("route.slack", meters: slackMeters)
            }

            if let assignedReel, let assessment {
                Divider()
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(assignedReel.name)
                            .font(.subheadline.weight(.semibold))
                        Text(RouteMath.formattedLength(meters: assignedReel.remainingLengthMeters, unitSystem: route.unitSystem))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Label {
                        Text(assessment.fits ? LocalizedStringKey("route.reel.fits") : LocalizedStringKey("route.reel.short"))
                    } icon: {
                        Image(systemName: assessment.fits ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(assessment.fits ? .green : .orange)
                }
            }
        }
    }

    private func metric(_ key: LocalizedStringKey, meters: Double) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(key)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(RouteMath.formattedLength(meters: meters, unitSystem: route.unitSystem))
                .font(.subheadline.monospacedDigit().weight(.semibold))
        }
    }
}

private struct CableProfileAssignmentView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var route: CableRoute
    @Query(sort: \CableProfile.name) private var profiles: [CableProfile]

    var body: some View {
        List {
            Button {
                assign(nil)
            } label: {
                selectionRow(title: String(localized: "profiles.none"), selected: route.profileID == nil)
            }

            ForEach(profiles) { profile in
                Button {
                    assign(profile)
                } label: {
                    selectionRow(title: profile.name, selected: route.profileID == profile.id)
                }
            }
        }
        .navigationTitle("profiles.profile")
    }

    private func selectionRow(title: String, selected: Bool) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.primary)
            Spacer()
            if selected {
                Image(systemName: "checkmark")
                    .foregroundStyle(.tint)
            }
        }
    }

    private func assign(_ profile: CableProfile?) {
        route.profileID = profile?.id
        route.updatedAt = .now
        modelContext.insert(
            HistoryEntry(
                routeID: route.id,
                kind: .updated,
                detail: profile?.name ?? String(localized: "profiles.none")
            )
        )
        try? modelContext.save()
        dismiss()
    }
}

private struct ReelAllocationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var route: CableRoute
    let requiredMeters: Double
    @Query(sort: \CableReel.updatedAt, order: .reverse) private var reels: [CableReel]

    private var candidates: [CableReel] {
        reels.filter { reel in
            reel.isActive && (route.profileID == nil || reel.profileID == nil || reel.profileID == route.profileID)
        }
    }

    var body: some View {
        List {
            if route.assignedReelID != nil {
                Section {
                    Button("route.reel.remove", role: .destructive) {
                        route.assignedReelID = nil
                        route.updatedAt = .now
                        try? modelContext.save()
                        dismiss()
                    }
                }
            }

            Section("route.reel.available") {
                if candidates.isEmpty {
                    Text("route.reel.empty")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(candidates) { reel in
                        let assessment = RouteMath.reelAssessment(
                            requiredMeters: requiredMeters,
                            availableMeters: reel.remainingLengthMeters
                        )
                        Button {
                            assign(reel)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: assessment.fits ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                    .foregroundStyle(assessment.fits ? .green : .orange)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(reel.name)
                                        .foregroundStyle(.primary)
                                        .font(.headline)
                                    Text(RouteMath.formattedLength(meters: reel.remainingLengthMeters, unitSystem: route.unitSystem))
                                        .font(.caption.monospacedDigit())
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if route.assignedReelID == reel.id {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.tint)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("route.reel.assign")
    }

    private func assign(_ reel: CableReel) {
        route.assignedReelID = reel.id
        route.updatedAt = .now
        modelContext.insert(
            HistoryEntry(routeID: route.id, kind: .reelAssigned, detail: reel.name)
        )
        try? modelContext.save()
        dismiss()
    }
}

extension HistoryKind {
    var symbolName: String {
        switch self {
        case .created: return "plus.circle"
        case .measured: return "ruler"
        case .updated: return "pencil"
        case .statusChanged: return "arrow.triangle.2.circlepath"
        case .reelAssigned: return "circle.dotted"
        case .photoAdded: return "photo"
        case .exported: return "doc.richtext"
        }
    }

    var localizedTitle: LocalizedStringKey {
        switch self {
        case .created: return "history.created"
        case .measured: return "history.measured"
        case .updated: return "history.updated"
        case .statusChanged: return "history.statusChanged"
        case .reelAssigned: return "history.reelAssigned"
        case .photoAdded: return "history.photoAdded"
        case .exported: return "history.exported"
        }
    }
}
