import SwiftUI
import SwiftData

struct InventoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Item.createdAt, order: .reverse) private var items: [Item]

    @State private var searchText = ""
    @State private var selectedCategory: ItemCategory? = nil
    @State private var showAddItem = false
    @State private var showingItem: Item? = nil

    private var filtered: [Item] {
        items.filter { item in
            let matchSearch = searchText.isEmpty
                || item.name.localizedCaseInsensitiveContains(searchText)
                || item.itemDescription.localizedCaseInsensitiveContains(searchText)
                || item.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            let matchCategory = selectedCategory == nil || item.category == selectedCategory
            return matchSearch && matchCategory
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    emptyState
                } else {
                    itemList
                }
            }
            .navigationTitle("Inventory")
            .searchable(text: $searchText, prompt: "Search items…")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showAddItem = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddItem) {
                AddItemView()
            }
            .sheet(item: $showingItem) { item in
                ItemDetailView(item: item)
            }
        }
    }

    // MARK: - Sub-views

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "archivebox")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            Text("No items yet")
                .font(.title2).bold()
            Text("Tap the camera tab to scan and add items,\nor tap + to add manually.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding()
    }

    private var itemList: some View {
        List {
            categoryFilter
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)

            ForEach(filtered) { item in
                ItemRowView(item: item)
                    .contentShape(Rectangle())
                    .onTapGesture { showingItem = item }
            }
            .onDelete(perform: deleteItems)
        }
        .listStyle(.plain)
    }

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(label: "All", icon: "square.grid.2x2", isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                }
                ForEach(ItemCategory.allCases) { cat in
                    FilterChip(label: cat.rawValue, icon: cat.icon, isSelected: selectedCategory == cat) {
                        selectedCategory = selectedCategory == cat ? nil : cat
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filtered[index])
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let label: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(label, systemImage: icon)
                .font(.caption).bold()
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}
