import SwiftUI
import SwiftData

struct RootView: View {
    var body: some View {
        TabView {
            ProjectsOverviewView()
                .tabItem { Label("tab.projects", systemImage: "folder") }

            RoutesOverviewView()
                .tabItem { Label("tab.routes", systemImage: "point.topleft.down.to.point.bottomright.curvepath") }

            ReelsOverviewView()
                .tabItem { Label("tab.reels", systemImage: "circle.dotted") }

            SettingsOverviewView()
                .tabItem { Label("tab.settings", systemImage: "gearshape") }
        }
    }
}

private struct ProjectsOverviewView: View {
    @Query(sort: \Project.updatedAt, order: .reverse) private var projects: [Project]

    var body: some View {
        NavigationStack {
            Group {
                if projects.isEmpty {
                    ContentUnavailableView(
                        "projects.empty.title",
                        systemImage: "folder.badge.plus",
                        description: Text("projects.empty.message")
                    )
                } else {
                    List(projects) { project in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(project.name)
                                .font(.headline)
                            if !project.siteName.isEmpty {
                                Text(project.siteName)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Text(project.updatedAt, style: .date)
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("tab.projects")
        }
    }
}

private struct RoutesOverviewView: View {
    @Query(sort: \CableRoute.updatedAt, order: .reverse) private var routes: [CableRoute]

    var body: some View {
        NavigationStack {
            Group {
                if routes.isEmpty {
                    ContentUnavailableView(
                        "routes.empty.title",
                        systemImage: "point.topleft.down.to.point.bottomright.curvepath",
                        description: Text("routes.empty.message")
                    )
                } else {
                    List(routes) { route in
                        HStack(spacing: 12) {
                            Image(systemName: statusSymbol(route.status))
                                .imageScale(.large)
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(route.name)
                                    .font(.headline)
                                Text(route.status.rawValue.capitalized)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("tab.routes")
        }
    }

    private func statusSymbol(_ status: RouteStatus) -> String {
        switch status {
        case .draft: "pencil.circle"
        case .ready: "checkmark.circle"
        case .pulled: "arrow.right.circle"
        case .verified: "checkmark.seal.fill"
        }
    }
}

private struct ReelsOverviewView: View {
    @Query(sort: \CableReel.updatedAt, order: .reverse) private var reels: [CableReel]
    @AppStorage("preferredUnitSystem") private var preferredUnitSystemRaw = UnitSystem.metric.rawValue

    private var preferredUnitSystem: UnitSystem {
        UnitSystem(rawValue: preferredUnitSystemRaw) ?? .metric
    }

    var body: some View {
        NavigationStack {
            Group {
                if reels.isEmpty {
                    ContentUnavailableView(
                        "reels.empty.title",
                        systemImage: "circle.dotted",
                        description: Text("reels.empty.message")
                    )
                } else {
                    List(reels) { reel in
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text(reel.name)
                                    .font(.headline)
                                Spacer()
                                if !reel.isActive {
                                    Image(systemName: "archivebox")
                                        .foregroundStyle(.secondary)
                                        .accessibilityLabel("reel.archived")
                                }
                            }
                            Text(RouteMath.formattedLength(meters: reel.remainingLengthMeters, unitSystem: preferredUnitSystem))
                                .font(.subheadline.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("tab.reels")
        }
    }
}

private struct SettingsOverviewView: View {
    @AppStorage("preferredUnitSystem") private var preferredUnitSystemRaw = UnitSystem.metric.rawValue

    var body: some View {
        NavigationStack {
            Form {
                Section("settings.measurement") {
                    Picker("settings.units", selection: $preferredUnitSystemRaw) {
                        Text("units.metric").tag(UnitSystem.metric.rawValue)
                        Text("units.imperial").tag(UnitSystem.imperial.rawValue)
                    }
                    .pickerStyle(.segmented)
                }

                Section("settings.about") {
                    LabeledContent("settings.storage", value: String(localized: "settings.storage.local"))
                    LabeledContent("settings.tracking", value: String(localized: "settings.tracking.none"))
                }
            }
            .navigationTitle("tab.settings")
        }
    }
}
