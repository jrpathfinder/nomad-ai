import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            InventoryView()
                .tabItem {
                    Label("Inventory", systemImage: "list.bullet.clipboard")
                }
                .tag(0)

            BoxesView()
                .tabItem {
                    Label("Boxes", systemImage: "shippingbox")
                }
                .tag(1)

            ScanView(onItemSaved: { selectedTab = 0 }, onClose: { selectedTab = 0 })
                .tabItem {
                    Label("Scan", systemImage: "camera.viewfinder")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(3)
        }
        .tint(.blue)
    }
}
