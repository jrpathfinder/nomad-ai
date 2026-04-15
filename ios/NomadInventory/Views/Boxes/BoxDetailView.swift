import SwiftUI
import SwiftData

struct BoxDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var box: MovingBox

    @State private var showQR = false
    @State private var showAddItem = false
    @State private var showingItem: Item? = nil
    @State private var isEditing = false
    @State private var editName = ""
    @State private var editLocation = ""

    private var boxColor: Color { Color(hex: box.color) ?? .blue }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    headerCard
                    qrButton
                    itemsSection
                }
                .padding()
            }
            .navigationTitle(box.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(isEditing ? "Save" : "Edit box") {
                            if isEditing { saveEdits() } else { beginEditing() }
                        }
                        Button(box.isSealed ? "Unseal" : "Seal box") {
                            box.isSealed.toggle()
                        }
                        Divider()
                        Button("Add item", systemImage: "plus") {
                            showAddItem = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showQR) {
                QRCodeView(box: box)
            }
            .sheet(isPresented: $showAddItem) {
                AddItemView(preselectBox: box)
            }
            .sheet(item: $showingItem) { item in
                ItemDetailView(item: item)
            }
        }
    }

    // MARK: - Header

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "shippingbox.fill")
                    .font(.largeTitle)
                    .foregroundStyle(boxColor)

                VStack(alignment: .leading) {
                    if isEditing {
                        TextField("Box name", text: $editName)
                            .font(.headline)
                            .textFieldStyle(.roundedBorder)
                    } else {
                        Text(box.name).font(.headline)
                    }

                    if isEditing {
                        TextField("Location", text: $editLocation)
                            .font(.subheadline)
                            .textFieldStyle(.roundedBorder)
                    } else if !box.location.isEmpty {
                        Label(box.location, systemImage: "mappin.circle")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if box.isSealed {
                    Label("Sealed", systemImage: "lock.fill")
                        .font(.caption)
                        .padding(6)
                        .background(Color.orange.opacity(0.15))
                        .foregroundStyle(.orange)
                        .clipShape(Capsule())
                }
            }

            Divider()

            // Category breakdown
            if !box.categorySummary.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(box.categorySummary.sorted(by: { $0.value > $1.value }), id: \.key) { key, count in
                            if let cat = ItemCategory(rawValue: key) {
                                Label("\(count) \(key)", systemImage: cat.icon)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(cat.color.opacity(0.12))
                                    .foregroundStyle(cat.color)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - QR Button

    private var qrButton: some View {
        Button {
            showQR = true
        } label: {
            HStack {
                Image(systemName: "qrcode")
                    .font(.title2)
                Text("Show QR Code Label")
                    .font(.headline)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(boxColor.opacity(0.1))
            .foregroundStyle(boxColor)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    // MARK: - Items

    private var itemsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Items (\(box.itemCount))")
                    .font(.headline)
                Spacer()
                Button {
                    showAddItem = true
                } label: {
                    Label("Add", systemImage: "plus")
                        .font(.subheadline)
                }
            }

            if box.items.isEmpty {
                Text("No items in this box yet.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(box.items.sorted(by: { $0.createdAt > $1.createdAt })) { item in
                        ItemRowView(item: item)
                            .contentShape(Rectangle())
                            .onTapGesture { showingItem = item }
                        Divider()
                    }
                }
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    // MARK: - Edit helpers

    private func beginEditing() {
        editName = box.name
        editLocation = box.location
        isEditing = true
    }

    private func saveEdits() {
        box.name = editName.trimmingCharacters(in: .whitespaces)
        box.location = editLocation.trimmingCharacters(in: .whitespaces)
        isEditing = false
    }
}
