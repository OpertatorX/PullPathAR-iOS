import SwiftUI
import SwiftData

@main
struct PullPathARApp: App {
    private let modelContainer: ModelContainer = {
        let schema = Schema([
            Project.self,
            CableRoute.self,
            RoutePoint.self,
            CableProfile.self,
            CableReel.self,
            PhotoNote.self,
            HistoryEntry.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Unable to initialize local data store: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(modelContainer)
    }
}
