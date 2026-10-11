import SwiftUI
import SwiftData

struct ProjectsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Project.updatedAt, order: .reverse) private var projects: [Project]
    @State private var searchText = ""
    @State private var showingCreateProject = false

    private var visibleProjects: [Project] {
        projects.filter { project in
            guard !project.isArchived else { return false }
            guard !searchText.isEmpty else { return true }
            return project.name.localizedCaseInsensitiveContains(searchText)
                || project.clientName.localizedCaseInsensitiveContains(searchText)
                || project.siteName.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if visibleProjects.isEmpty {
                    ContentUnavailableView(
                        LocalizedStringKey(searchText.isEmpty ? "projects.empty.title" : "projects.search.empty"),
                        systemImage: searchText.isEmpty ? "folder.badge.plus" : "magnifyingglass",
                        description: Text(LocalizedStringKey(searchText.isEmpty ? "projects.empty.message" : "projects.search.message"))
                    )
                } else {
                    List {
                        ForEach(visibleProjects) { project in
                            NavigationLink {
                                ProjectDetailView(project: project)
                            } label: {
                                ProjectRow(project: project)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button("projects.archive", systemImage: "archivebox") {
                                    project.isArchived = true
                                    project.updatedAt = .now
                                    try? modelContext.save()
                                }
                                .tint(.orange)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("tab.projects")
            .searchable(text: $searchText, prompt: "projects.search.prompt")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("projects.create", systemImage: "plus") {
                        showingCreateProject = true
                    }
                    .accessibilityHint("projects.create.hint")
                }
            }
            .sheet(isPresented: $showingCreateProject) {
                CreateProjectView()
            }
        }
    }
}

private struct ProjectRow: View {
    let project: Project

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(project.name)
                .font(.headline)
            if !project.siteName.isEmpty {
                Label(project.siteName, systemImage: "mappin.and.ellipse")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if !project.clientName.isEmpty {
                Text(project.clientName)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 5)
    }
}

private struct CreateProjectView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var name = ""
    @State private var clientName = ""
    @State private var siteName = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("projects.new.details") {
                    TextField("projects.name", text: $name)
                    TextField("projects.client", text: $clientName)
                    TextField("projects.site", text: $siteName)
                }
            }
            .navigationTitle("projects.new.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.create") {
                        let project = Project(
                            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                            clientName: clientName.trimmingCharacters(in: .whitespacesAndNewlines),
                            siteName: siteName.trimmingCharacters(in: .whitespacesAndNewlines)
                        )
                        modelContext.insert(project)
                        try? modelContext.save()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

struct ProjectDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CableRoute.updatedAt, order: .reverse) private var allRoutes: [CableRoute]
    let project: Project
    @State private var showingCreateRoute = false

    private var routes: [CableRoute] {
        allRoutes.filter { $0.projectID == project.id }
    }

    var body: some View {
        List {
            if !project.clientName.isEmpty || !project.siteName.isEmpty {
                Section("projects.detail.site") {
                    if !project.clientName.isEmpty {
                        LabeledContent("projects.client", value: project.clientName)
                    }
                    if !project.siteName.isEmpty {
                        LabeledContent("projects.site", value: project.siteName)
                    }
                }
            }

            Section("projects.detail.routes") {
                if routes.isEmpty {
                    Text("routes.empty.message")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(routes) { route in
                        NavigationLink {
                            RouteDetailView(route: route, project: project)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: route.status.symbolName)
                                    .foregroundStyle(route.status.tint)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(route.name)
                                        .font(.headline)
                                    Text(route.status.localizedTitle)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .onDelete { offsets in
                        for index in offsets {
                            let route = routes[index]
                            deleteRoute(route)
                        }
                    }
                }
            }
        }
        .navigationTitle(project.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("routes.create", systemImage: "plus") {
                    showingCreateRoute = true
                }
            }
        }
        .sheet(isPresented: $showingCreateRoute) {
            CreateRouteView(projectID: project.id)
        }
    }

    private func deleteRoute(_ route: CableRoute) {
        let descriptor = FetchDescriptor<RoutePoint>()
        let points = (try? modelContext.fetch(descriptor))?.filter { $0.routeID == route.id } ?? []
        for point in points { modelContext.delete(point) }
        let photoDescriptor = FetchDescriptor<PhotoNote>()
        let photos = (try? modelContext.fetch(photoDescriptor))?.filter { $0.routeID == route.id } ?? []
        for photo in photos { modelContext.delete(photo) }
        let historyDescriptor = FetchDescriptor<HistoryEntry>()
        let history = (try? modelContext.fetch(historyDescriptor))?.filter { $0.routeID == route.id } ?? []
        for entry in history { modelContext.delete(entry) }
        modelContext.delete(route)
        try? modelContext.save()
    }
}

private struct CreateRouteView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let projectID: UUID
    @State private var name = ""
    @State private var unitSystem = UnitSystem.metric

    var body: some View {
        NavigationStack {
            Form {
                Section("routes.new.details") {
                    TextField("routes.name", text: $name)
                    Picker("settings.units", selection: $unitSystem) {
                        Text("units.metric").tag(UnitSystem.metric)
                        Text("units.imperial").tag(UnitSystem.imperial)
                    }
                }
            }
            .navigationTitle("routes.new.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.create") {
                        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        let route = CableRoute(projectID: projectID, name: cleanName, unitSystem: unitSystem)
                        modelContext.insert(route)
                        modelContext.insert(HistoryEntry(routeID: route.id, kind: .created, detail: cleanName))
                        try? modelContext.save()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

extension RouteStatus {
    var symbolName: String {
        switch self {
        case .draft: return "pencil.circle"
        case .ready: return "checkmark.circle"
        case .pulled: return "arrow.right.circle"
        case .verified: return "checkmark.seal.fill"
        }
    }

    var tint: Color {
        switch self {
        case .draft: return .secondary
        case .ready: return .blue
        case .pulled: return .orange
        case .verified: return .green
        }
    }

    var localizedTitle: LocalizedStringKey {
        switch self {
        case .draft: return "route.status.draft"
        case .ready: return "route.status.ready"
        case .pulled: return "route.status.pulled"
        case .verified: return "route.status.verified"
        }
    }

    var localizedString: String {
        switch self {
        case .draft: return String(localized: "route.status.draft")
        case .ready: return String(localized: "route.status.ready")
        case .pulled: return String(localized: "route.status.pulled")
        case .verified: return String(localized: "route.status.verified")
        }
    }
}
