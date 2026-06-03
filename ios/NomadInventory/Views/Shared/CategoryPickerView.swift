import SwiftUI

struct CategoryPickerView: View {
    @Binding var selection: ItemCategory

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(ItemCategory.allCases) { cat in
                Button { selection = cat } label: {
                    VStack(spacing: 5) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selection == cat ? cat.color : cat.color.opacity(0.12))
                                .frame(height: 52)
                            Image(systemName: cat.icon)
                                .font(.title2)
                                .foregroundStyle(selection == cat ? .white : cat.color)
                        }
                        Text(cat.rawValue)
                            .font(.caption2)
                            .lineLimit(1)
                            .foregroundStyle(selection == cat ? cat.color : .secondary)
                            .fontWeight(selection == cat ? .semibold : .regular)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }
}
