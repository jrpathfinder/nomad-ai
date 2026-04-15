import SwiftUI

struct QRCodeView: View {
    @Environment(\.dismiss) private var dismiss
    let box: MovingBox

    @State private var showShareSheet = false
    @State private var labelImage: UIImage? = nil
    @State private var qrImage: UIImage? = nil

    private var boxColor: Color { Color(hex: box.color) ?? .blue }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // QR code display
                    VStack(spacing: 16) {
                        if let qr = qrImage {
                            Image(uiImage: qr)
                                .resizable()
                                .interpolation(.none)
                                .scaledToFit()
                                .frame(width: 240, height: 240)
                                .padding(20)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: .black.opacity(0.08), radius: 12)
                        }

                        VStack(spacing: 4) {
                            Text(box.name)
                                .font(.title2).bold()
                            if !box.location.isEmpty {
                                Text(box.location)
                                    .foregroundStyle(.secondary)
                            }
                            Text("\(box.itemCount) item\(box.itemCount == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Category summary chips
                    if !box.categorySummary.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Contents").font(.headline)
                            FlowLayout(spacing: 8) {
                                ForEach(box.categorySummary.sorted(by: { $0.value > $1.value }), id: \.key) { key, count in
                                    if let cat = ItemCategory(rawValue: key) {
                                        Label("\(count)× \(key)", systemImage: cat.icon)
                                            .font(.caption)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(cat.color.opacity(0.12))
                                            .foregroundStyle(cat.color)
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    // Action buttons
                    VStack(spacing: 12) {
                        Button {
                            labelImage = QRCodeService.labelImage(for: box, size: 400)
                            showShareSheet = true
                        } label: {
                            Label("Share / Print Label", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(boxColor)

                        Text("Print and stick on your box to scan later.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding()
            }
            .navigationTitle("QR Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                qrImage = QRCodeService.generate(from: box.qrPayload, size: 480)
                labelImage = QRCodeService.labelImage(for: box, size: 400)
            }
            .sheet(isPresented: $showShareSheet) {
                if let img = labelImage {
                    ShareSheet(items: [img])
                }
            }
        }
    }
}

// MARK: - UIActivityViewController wrapper

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
