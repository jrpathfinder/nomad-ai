import SwiftUI
import SwiftData

struct ItemDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var boxes: [MovingBox]

    @Bindable var item: Item

    @State private var isEditing = false
    @State private var editName = ""
    @State private var editDescription = ""
    @State private var editCategory: ItemCategory = .other
    @State private var editTags = ""
    @State private var selectedBox: MovingBox? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    photoSection
                    infoSection
                    boxSection
                    tagsSection
                    metaSection
                }
                .padding()
            }
            .navigationTitle(isEditing ? "Edit Item" : item.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditing ? "Save" : "Edit") {
                        if isEditing { saveEdits() }
                        else { beginEditing() }
                    }
                    .fontWeight(isEditing ? .bold : .regular)
                }
            }
        }
    }

    // MARK: - Sections

    private var photoSection: some View {
        Group {
            if let data = item.photoData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(item.category.color.opacity(0.15))
                    .frame(height: 180)
                    .overlay(
                        Image(systemName: item.category.icon)
                            .font(.system(size: 64))
                            .foregroundStyle(item.category.color)
                    )
            }
        }
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if isEditing {
                TextField("Item name", text: $editName)
                    .font(.title2).bold()
                    .textFieldStyle(.roundedBorder)

                TextField("Description (optional)", text: $editDescription, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3...6)

                Picker("Category", selection: $editCategory) {
                    ForEach(ItemCategory.allCases) { cat in
                        Label(cat.rawValue, systemImage: cat.icon).tag(cat)
                    }
                }
                .pickerStyle(.menu)
            } else {
                Text(item.name).font(.title2).bold()
                if !item.itemDescription.isEmpty {
                    Text(item.itemDescription).foregroundStyle(.secondary)
                }
                Label(item.category.rawValue, systemImage: item.category.icon)
                    .foregroundStyle(item.category.color)
                    .font(.subheadline)
            }
        }
    }

    private var boxSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Box").font(.headline)

            if isEditing {
                Picker("Assign to box", selection: $selectedBox) {
                    Text("No box").tag(Optional<MovingBox>.none)
                    ForEach(boxes) { box in
                        Text(box.name).tag(Optional(box))
                    }
                }
                .pickerStyle(.menu)
            } else {
                if let box = item.box {
                    Label(box.name, systemImage: "shippingbox")
                        .foregroundStyle(.blue)
                } else {
                    Text("Not assigned to any box")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tags").font(.headline)

            if isEditing {
                TextField("tag1, tag2, tag3", text: $editTags)
                    .textFieldStyle(.roundedBorder)
                Text("Separate tags with commas")
                    .font(.caption).foregroundStyle(.secondary)
            } else {
                if item.tags.isEmpty {
                    Text("No tags").foregroundStyle(.secondary)
                } else {
                    FlowLayout(spacing: 6) {
                        ForEach(item.tags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.12))
                                .foregroundStyle(.blue)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var metaSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Added: \(item.createdAt.formatted(date: .abbreviated, time: .shortened))")
                .font(.caption).foregroundStyle(.secondary)
            Text("Updated: \(item.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    // MARK: - Actions

    private func beginEditing() {
        editName = item.name
        editDescription = item.itemDescription
        editCategory = item.category
        editTags = item.tags.joined(separator: ", ")
        selectedBox = item.box
        isEditing = true
    }

    private func saveEdits() {
        item.name = editName.trimmingCharacters(in: .whitespaces)
        item.itemDescription = editDescription.trimmingCharacters(in: .whitespaces)
        item.category = editCategory
        item.tags = editTags
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        item.box = selectedBox
        item.updatedAt = Date()
        isEditing = false
    }
}

// MARK: - Simple flow layout for tags

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        let height = rows.map(\.height).reduce(0, +) + CGFloat(max(rows.count - 1, 0)) * spacing
        return CGSize(width: proposal.width ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            for subview in row.subviews {
                let size = subview.sizeThatFits(.unspecified)
                subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private struct Row { var subviews: [LayoutSubview]; var height: CGFloat }

    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [Row] {
        let maxWidth = proposal.width ?? .infinity
        var rows = [Row]()
        var currentSubviews = [LayoutSubview]()
        var currentWidth: CGFloat = 0
        var currentHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentWidth + size.width > maxWidth, !currentSubviews.isEmpty {
                rows.append(Row(subviews: currentSubviews, height: currentHeight))
                currentSubviews = []
                currentWidth = 0
                currentHeight = 0
            }
            currentSubviews.append(subview)
            currentWidth += size.width + spacing
            currentHeight = max(currentHeight, size.height)
        }
        if !currentSubviews.isEmpty {
            rows.append(Row(subviews: currentSubviews, height: currentHeight))
        }
        return rows
    }
}
