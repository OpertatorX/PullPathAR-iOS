import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            ProjectsView()
                .tabItem { Label("tab.projects", systemImage: "folder") }

            AllRoutesView()
                .tabItem { Label("tab.routes", systemImage: "point.topleft.down.to.point.bottomright.curvepath") }

            ReelsView()
                .tabItem { Label("tab.reels", systemImage: "circle.dotted") }

            AppSettingsView()
                .tabItem { Label("tab.settings", systemImage: "gearshape") }
        }
    }
}

private struct AppSettingsView: View {
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

                Section("settings.cables") {
                    NavigationLink {
                        CableProfilesView()
                    } label: {
                        Label("profiles.manage", systemImage: "cable.connector")
                    }
                }

                Section("settings.about") {
                    LabeledContent("settings.storage", value: String(localized: "settings.storage.local"))
                    LabeledContent("settings.tracking", value: String(localized: "settings.tracking.none"))
                    LabeledContent("settings.account", value: String(localized: "settings.account.none"))
                }

                Section {
                    Text("settings.measurement.disclaimer")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("tab.settings")
        }
    }
}
