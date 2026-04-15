import SwiftUI
import SwiftData

/// Shown after AI identifies the photographed object.
/// User can review, edit name/category, assign a box, then save.
struct ItemConfirmView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var boxes: [MovingBox]

    let photo: UIImage
    let identified: IdentifiedItem?
    let onSave: () -> Void
    let onRetake: () -> Void

    @State private var name: String = ""
    @State private var description: String = ""
    @State private var category: ItemCategory = .other
    @State private var tags: String = ""
    @State private var selectedBox: MovingBox? = nil
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Photo preview
                    Image(uiImage: photo)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: 280)
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                    // AI result badge
                    if let id = identified {
                        if id.confidence > 0 {
                            HStack {
                                Image(systemName: "sparkles")
                                Text("AI identified with \(Int(id.confidence * 100))% confidence")
                                    .font(.caption)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.1))
                            .foregroundStyle(.blue)
                            .clipShape(Capsule())
                        } else {
                            // Show why AI failed
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("AI recognition failed")
                                        .font(.caption).bold()
                                    Text(id.description.isEmpty ? "Check Settings → enter your API key" : id.description)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.orange.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }

                    // Editable fields
                    VStack(alignment: .leading, spacing: 16) {
                        fieldGroup(title: "Name") {
                            TextField("Item name", text: $name)
                                .textFieldStyle(.roundedBorder)
                        }

                        fieldGroup(title: "Description") {
                            TextField("Short description", text: $description, axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                                .lineLimit(2...4)
                        }

                        fieldGroup(title: "Category") {
                            Picker("Category", selection: $category) {
                                ForEach(ItemCategory.allCases) { cat in
                                    Label(cat.rawValue, systemImage: cat.icon).tag(cat)
                                }
                            }
                            .pickerStyle(.menu)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }

                        fieldGroup(title: "Box (optional)") {
                            Picker("Box", selection: $selectedBox) {
                                Text("No box").tag(Optional<MovingBox>.none)
                                ForEach(boxes) { box in
                                    Label(box.name, systemImage: "shippingbox").tag(Optional(box))
                                }
                            }
                            .pickerStyle(.menu)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }

                        fieldGroup(title: "Tags") {
                            TextField("tag1, tag2", text: $tags)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Confirm Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Retake", action: onRetake)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveItem() }
                        .bold()
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                }
            }
            .onAppear { populateFromAI() }
        }
    }

    // MARK: - Helpers

    private func fieldGroup<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            content()
        }
    }

    private func populateFromAI() {
        guard let id = identified else { return }
        name = id.name
        description = id.description
        category = id.suggestedCategory
        tags = id.suggestedTags.joined(separator: ", ")
    }

    private func saveItem() {
        isSaving = true
        let parsedTags = tags
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        let item = Item(
            name: name.trimmingCharacters(in: .whitespaces),
            description: description.trimmingCharacters(in: .whitespaces),
            category: category,
            photoData: photo.jpegData(compressionQuality: 0.85),
            tags: parsedTags,
            box: selectedBox
        )
        modelContext.insert(item)
        onSave()
    }
}
