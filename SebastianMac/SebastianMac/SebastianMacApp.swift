import SwiftUI
import SwiftData

@main
struct SebastianMacApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            TaskItem.self,
            Memo.self,
            DailyNippo.self,
            WeeklyShuho.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .modelContainer(sharedModelContainer)
    }
}
