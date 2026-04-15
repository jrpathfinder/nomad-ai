import SwiftUI

struct ItemRowView: View {
    let item: Item

    var body: some View {
        HStack(spacing: 12) {
            // Photo or category icon
            Group {
                if let data = item.photoData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: item.category.icon)
                        .font(.title2)
                        .foregroundStyle(item.category.color)
                }
            }
            .frame(width: 56, height: 56)
            .background(item.category.color.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                    .lineLimit(1)

                if !item.itemDescription.isEmpty {
                    Text(item.itemDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                HStack(spacing: 6) {
                    Label(item.category.rawValue, systemImage: item.category.icon)
                        .font(.caption2)
                        .foregroundStyle(item.category.color)

                    if let box = item.box {
                        Label(box.name, systemImage: "shippingbox")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiaryLabel)
        }
        .padding(.vertical, 4)
    }
}
