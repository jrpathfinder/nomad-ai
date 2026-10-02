import SwiftUI
import SwiftData

@main
struct NomadInventoryApp: App {
    let container: ModelContainer
    @StateObject private var lang = LocalizationManager()
    @StateObject private var store = SubscriptionManager()

    init() {
        do {
            container = try ModelContainer(for: Item.self, MovingBox.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(lang)
                .environmentObject(store)
        }
        .modelContainer(container)
    }
}
