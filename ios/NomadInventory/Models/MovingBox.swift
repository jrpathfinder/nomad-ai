import Foundation
import SwiftData

@Model
final class MovingBox {
    @Attribute(.unique) var id: UUID
    var name: String
    var boxDescription: String
    var location: String        // e.g. "Living Room", "Storage"
    var color: String           // label color hex for visual identification
    var isSealed: Bool
    var createdAt: Date

    // Inverse relationship — all items packed in this box
    @Relationship(deleteRule: .nullify, inverse: \Item.box)
    var items: [Item]

    init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        location: String = "",
        color: String = "#007AFF",
        isSealed: Bool = false
    ) {
        self.id = id
        self.name = name
        self.boxDescription = description
        self.location = location
        self.color = color
        self.isSealed = isSealed
        self.items = []
        self.createdAt = Date()
    }

    var itemCount: Int { items.count }

    // QR code payload — compact JSON with box id, name, and item count
    var qrPayload: String {
        let payload: [String: String] = [
            "id": id.uuidString,
            "name": name,
            "location": location,
            "count": "\(itemCount)"
        ]
        if let data = try? JSONSerialization.data(withJSONObject: payload),
           let string = String(data: data, encoding: .utf8) {
            return string
        }
        return "nomad://box/\(id.uuidString)"
    }

    // Summary of item categories inside this box
    var categorySummary: [String: Int] {
        var summary = [String: Int]()
        for item in items {
            summary[item.category.rawValue, default: 0] += 1
        }
        return summary
    }
}
