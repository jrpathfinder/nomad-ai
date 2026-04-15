import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var showSettings = false

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

            ScanView(onItemSaved: { selectedTab = 0 })
                .tabItem {
                    Label("Scan", systemImage: "camera.viewfinder")
                }
                .tag(2)
        }
        .tint(.blue)
        .overlay(alignment: .topTrailing) {
            // Global settings button visible from any tab
            if selectedTab != 2 {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .font(.title3)
                        .padding(12)
                }
                .padding(.trailing, 4)
                .sheet(isPresented: $showSettings) {
                    SettingsView()
                }
            }
        }
    }
}
