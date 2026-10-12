import SwiftUI

struct RootView: View {
    var body: some View {
#if DEBUG
        if let mode = StoreScreenshotMode.current {
            StoreScreenshotRoot(mode: mode)
        } else {
            mainTabs
        }
#else
        mainTabs
#endif
    }

    private var mainTabs: some View {
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
                Section {
                    HStack(spacing: 16) {
                        Image("BrandMark")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 68, height: 68)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(.white.opacity(0.10), lineWidth: 1)
                            }
                            .shadow(color: .black.opacity(0.18), radius: 10, y: 6)

                        VStack(alignment: .leading, spacing: 5) {
                            Text("PullPath AR")
                                .font(.title3.weight(.semibold))
                            Text("brand.tagline")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .listRowBackground(Color.clear)

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
