import SwiftUI
import SwiftData
import PhotosUI

struct AddItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var boxes: [MovingBox]

    // Optional pre-fill from AI scan
    var prefill: IdentifiedItem? = nil
    var prefillPhoto: UIImage? = nil
    var preselectBox: MovingBox? = nil

    @State private var name = ""
    @State private var description = ""
    @State private var category: ItemCategory = .other
    @State private var tags = ""
    @State private var selectedBox: MovingBox? = nil
    @State private var photoData: Data? = nil
    @State private var photoItem: PhotosPickerItem? = nil

    var body: some View {
        NavigationStack {
            Form {
                photoSection
                detailsSection
                categorySection
                boxSection
                tagsSection
            }
            .navigationTitle("New Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveItem() }
                        .bold()
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear { applyPrefill() }
        }
    }

    // MARK: - Sections

    private var photoSection: some View {
        Section {
            HStack {
                Spacer()
                Group {
                    if let data = photoData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 160, height: 160)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    } else {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(.systemGray5))
                            .frame(width: 160, height: 160)
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                    .foregroundStyle(.secondary)
                            )
                    }
                }
                Spacer()
            }

            PhotosPicker(selection: $photoItem, matching: .images) {
                Label("Choose photo", systemImage: "photo.on.rectangle")
            }
            .onChange(of: photoItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        photoData = data
                    }
                }
            }
        }
    }

    private var detailsSection: some View {
        Section("Details") {
            TextField("Item name", text: $name)
            TextField("Description (optional)", text: $description, axis: .vertical)
                .lineLimit(2...4)
        }
    }

    private var categorySection: some View {
        Section("Category") {
            Picker("Category", selection: $category) {
                ForEach(ItemCategory.allCases) { cat in
                    Label(cat.rawValue, systemImage: cat.icon).tag(cat)
                }
            }
            .pickerStyle(.navigationLink)
        }
    }

    private var boxSection: some View {
        Section("Box") {
            Picker("Assign to box", selection: $selectedBox) {
                Text("No box").tag(Optional<MovingBox>.none)
                ForEach(boxes) { box in
                    Label(box.name, systemImage: "shippingbox").tag(Optional(box))
                }
            }
            .pickerStyle(.navigationLink)
        }
    }

    private var tagsSection: some View {
        Section("Tags") {
            TextField("tag1, tag2, tag3", text: $tags)
            Text("Separate with commas")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Actions

    private func applyPrefill() {
        if let p = prefill {
            name = p.name
            description = p.description
            category = p.suggestedCategory
            tags = p.suggestedTags.joined(separator: ", ")
        }
        if let photo = prefillPhoto {
            photoData = photo.jpegData(compressionQuality: 0.85)
        }
        selectedBox = preselectBox
    }

    private func saveItem() {
        let parsedTags = tags
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        let item = Item(
            name: name.trimmingCharacters(in: .whitespaces),
            description: description.trimmingCharacters(in: .whitespaces),
            category: category,
            photoData: photoData,
            tags: parsedTags,
            box: selectedBox
        )
        modelContext.insert(item)
        dismiss()
    }
}
