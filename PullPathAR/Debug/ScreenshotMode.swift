#if DEBUG
import SwiftUI
import SwiftData

enum StoreScreenshotMode: String {
    case projects
    case route
    case reels
    case routes
    case editor

    static var current: StoreScreenshotMode? {
        guard let value = ProcessInfo.processInfo.arguments.first(where: { $0.hasPrefix("--screenshot=") }) else { return nil }
        return StoreScreenshotMode(rawValue: String(value.dropFirst("--screenshot=".count)))
    }

    static var isFrench: Bool {
        Locale.current.language.languageCode?.identifier == "fr"
    }
}

struct StoreScreenshotRoot: View {
    @Environment(\.modelContext) private var modelContext
    @State private var seededProject: Project?
    @State private var seededRoute: CableRoute?
    let mode: StoreScreenshotMode

    var body: some View {
        Group {
            if let project = seededProject, let route = seededRoute {
                screenshotContent(project: project, route: route)
            } else {
                ProgressView()
                    .task { seedDeterministicData() }
            }
        }
    }

    @ViewBuilder
    private func screenshotContent(project: Project, route: CableRoute) -> some View {
        switch mode {
        case .projects:
            ProjectsView()
        case .route:
            NavigationStack { RouteDetailView(route: route, project: project) }
        case .reels:
            ReelsView()
        case .routes:
            AllRoutesView()
        case .editor:
            NavigationStack { RouteEditorView(route: route) }
        }
    }

    @MainActor
    private func seedDeterministicData() {
        clear(Project.self)
        clear(CableRoute.self)
        clear(RoutePoint.self)
        clear(CableProfile.self)
        clear(CableReel.self)
        clear(PhotoNote.self)
        clear(HistoryEntry.self)

        let fr = StoreScreenshotMode.isFrench
        let project = Project(
            name: fr ? "Rénovation réseau — Tour B" : "Network Upgrade — Tower B",
            clientName: fr ? "Bureaux Rivoli" : "Riverside Offices",
            siteName: fr ? "Niveau 3 • Local technique" : "Level 3 • Telecom Room"
        )
        let profile = CableProfile(
            name: "Cat6A F/UTP",
            category: .cat6a,
            diameterMillimeters: 7.2,
            minimumBendRadiusMillimeters: 36
        )
        let reel = CableReel(
            name: "R-07",
            profileID: profile.id,
            initialLengthMeters: 305,
            remainingLengthMeters: 212.4,
            notes: fr ? "Bobine chantier vérifiée" : "Verified site reel"
        )
        let route = CableRoute(
            projectID: project.id,
            name: fr ? "Baie principale → Étage 3" : "Main Rack → Floor 3",
            profileID: profile.id,
            assignedReelID: reel.id,
            status: .ready,
            unitSystem: .metric,
            fixedSlackMeters: 3,
            slackPercent: 12,
            notes: fr ? "Passage par faux plafond, descente côté est." : "Ceiling route with east-side drop."
        )

        modelContext.insert(project)
        modelContext.insert(profile)
        modelContext.insert(reel)
        modelContext.insert(route)

        let points: [(Double, Double, Double)] = [
            (0.0, 0.0, 0.0),
            (4.8, 0.1, 0.0),
            (9.2, 0.9, 0.0),
            (13.0, 2.8, 1.0),
            (17.6, 2.8, 1.0)
        ]
        for (index, point) in points.enumerated() {
            modelContext.insert(RoutePoint(
                routeID: route.id,
                orderIndex: index,
                xMeters: point.0,
                yMeters: point.1,
                zMeters: point.2,
                source: .augmentedReality,
                label: "Point \(index + 1)"
            ))
        }

        modelContext.insert(HistoryEntry(routeID: route.id, kind: .created, detail: route.name))
        modelContext.insert(HistoryEntry(routeID: route.id, kind: .measured, detail: fr ? "Tracé AR enregistré" : "AR route captured"))
        modelContext.insert(HistoryEntry(routeID: route.id, kind: .reelAssigned, detail: "R-07"))
        modelContext.insert(HistoryEntry(routeID: route.id, kind: .statusChanged, detail: fr ? "Prêt pour tirage" : "Ready to pull"))

        try? modelContext.save()
        seededProject = project
        seededRoute = route
    }

    @MainActor
    private func clear<T: PersistentModel>(_ type: T.Type) {
        if let values = try? modelContext.fetch(FetchDescriptor<T>()) {
            values.forEach { modelContext.delete($0) }
        }
    }
}
#endif
