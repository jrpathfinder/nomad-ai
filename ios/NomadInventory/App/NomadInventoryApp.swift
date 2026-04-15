import SwiftUI
import SwiftData

@main
struct NomadInventoryApp: App {
    let container: ModelContainer

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
        }
        .modelContainer(container)
    }
}
