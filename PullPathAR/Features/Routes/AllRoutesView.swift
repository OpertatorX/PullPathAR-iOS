import SwiftUI
import SwiftData

struct AllRoutesView: View {
    @Query(sort: \CableRoute.updatedAt, order: .reverse) private var routes: [CableRoute]
    @Query private var projects: [Project]
    @State private var searchText = ""
    @State private var statusFilter: RouteStatus?

    private var filteredRoutes: [CableRoute] {
        routes.filter { route in
            let matchesStatus = statusFilter == nil || route.status == statusFilter
            let projectName = projects.first(where: { $0.id == route.projectID })?.name ?? ""
            let matchesSearch = searchText.isEmpty
                || route.name.localizedCaseInsensitiveContains(searchText)
                || projectName.localizedCaseInsensitiveContains(searchText)
            return matchesStatus && matchesSearch
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if filteredRoutes.isEmpty {
                    ContentUnavailableView(
                        LocalizedStringKey(searchText.isEmpty && statusFilter == nil ? "routes.empty.title" : "routes.search.empty"),
                        systemImage: "point.topleft.down.to.point.bottomright.curvepath",
                        description: Text(LocalizedStringKey(searchText.isEmpty && statusFilter == nil ? "routes.empty.message" : "routes.search.message"))
                    )
                } else {
                    List(filteredRoutes) { route in
                        if let project = projects.first(where: { $0.id == route.projectID }) {
                            NavigationLink {
                                RouteDetailView(route: route, project: project)
                            } label: {
                                routeRow(route, projectName: project.name)
                            }
                        } else {
                            routeRow(route, projectName: String(localized: "routes.project.missing"))
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("tab.routes")
            .searchable(text: $searchText, prompt: "routes.search.prompt")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("routes.filter.all") { statusFilter = nil }
                        Divider()
                        ForEach(RouteStatus.allCases) { status in
                            Button {
                                statusFilter = status
                            } label: {
                                Label(status.localizedTitle, systemImage: status.symbolName)
                            }
                        }
                    } label: {
                        Image(systemName: statusFilter == nil ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                    }
                    .accessibilityLabel("routes.filter")
                }
            }
        }
    }

    @ViewBuilder
    private func routeRow(_ route: CableRoute, projectName: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: route.status.symbolName)
                .foregroundStyle(route.status.tint)
                .imageScale(.large)
            VStack(alignment: .leading, spacing: 4) {
                Text(route.name)
                    .font(.headline)
                Text(projectName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(route.status.localizedTitle)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}
