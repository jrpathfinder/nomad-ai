import SwiftUI
import SwiftData

struct BoxesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MovingBox.createdAt, order: .reverse) private var boxes: [MovingBox]

    @State private var showAddBox = false
    @State private var selectedBox: MovingBox? = nil

    var body: some View {
        NavigationStack {
            Group {
                if boxes.isEmpty {
                    emptyState
                } else {
                    boxGrid
                }
            }
            .navigationTitle("Boxes")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showAddBox = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddBox) {
                AddBoxView()
            }
            .sheet(item: $selectedBox) { box in
                BoxDetailView(box: box)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "shippingbox")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            Text("No boxes yet")
                .font(.title2).bold()
            Text("Create boxes to organise your items\nand generate QR code labels.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("Create first box") { showAddBox = true }
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private var boxGrid: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(boxes) { box in
                    BoxCardView(box: box)
                        .onTapGesture { selectedBox = box }
                }
            }
            .padding()
        }
    }
}

// MARK: - Box Card

struct BoxCardView: View {
    let box: MovingBox

    private var boxColor: Color {
        Color(hex: box.color) ?? .blue
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "shippingbox.fill")
                    .font(.title)
                    .foregroundStyle(boxColor)
                Spacer()
                if box.isSealed {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Text(box.name)
                .font(.headline)
                .lineLimit(2)

            if !box.location.isEmpty {
                Label(box.location, systemImage: "mappin.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            HStack {
                Text("\(box.itemCount) item\(box.itemCount == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: "qrcode")
                    .font(.caption)
                    .foregroundStyle(boxColor)
            }
        }
        .padding()
        .background(boxColor.opacity(0.10))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(boxColor.opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Add Box

struct AddBoxView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var description = ""
    @State private var location = ""
    @State private var selectedColor = "#007AFF"

    private let colors = ["#007AFF", "#34C759", "#FF9500", "#FF3B30",
                          "#AF52DE", "#5AC8FA", "#FF2D55", "#A2845E"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Box Details") {
                    TextField("Box name (e.g. Kitchen 1)", text: $name)
                    TextField("Description (optional)", text: $description)
                    TextField("Location (e.g. Living Room)", text: $location)
                }

                Section("Label Colour") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 12) {
                        ForEach(colors, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex) ?? .blue)
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle()
                                        .strokeBorder(.white, lineWidth: selectedColor == hex ? 3 : 0)
                                        .padding(2)
                                )
                                .onTapGesture { selectedColor = hex }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("New Box")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") { createBox() }
                        .bold()
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func createBox() {
        let box = MovingBox(
            name: name.trimmingCharacters(in: .whitespaces),
            description: description.trimmingCharacters(in: .whitespaces),
            location: location.trimmingCharacters(in: .whitespaces),
            color: selectedColor
        )
        modelContext.insert(box)
        dismiss()
    }
}

// MARK: - Color(hex:) extension

extension Color {
    init?(hex: String) {
        var h = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if h.hasPrefix("#") { h.removeFirst() }
        guard h.count == 6, let value = UInt64(h, radix: 16) else { return nil }
        let r = Double((value >> 16) & 0xFF) / 255
        let g = Double((value >> 8) & 0xFF) / 255
        let b = Double(value & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
