import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var lang: LocalizationManager
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            InventoryView()
                .tabItem { Label(lang.s(.tabInventory), systemImage: "list.bullet.clipboard") }
                .tag(0)

            BoxesView()
                .tabItem { Label(lang.s(.tabBoxes), systemImage: "shippingbox") }
                .tag(1)

            ScanView(onItemSaved: { selectedTab = 0 }, onClose: { selectedTab = 0 })
                .tabItem { Label(lang.s(.tabScan), systemImage: "camera.viewfinder") }
                .tag(2)

            SettingsView()
                .tabItem { Label(lang.s(.tabSettings), systemImage: "gearshape") }
                .tag(3)
        }
        .tint(.blue)
    }
}
