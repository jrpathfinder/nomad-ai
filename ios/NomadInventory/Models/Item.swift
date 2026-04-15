import Foundation
import SwiftData

@Model
final class Item {
    @Attribute(.unique) var id: UUID
    var name: String
    var itemDescription: String
    var categoryRaw: String
    var photoData: Data?
    var tags: [String]
    var createdAt: Date
    var updatedAt: Date

    // Relationship to box (optional — item can be unboxed)
    var box: MovingBox?

    init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        category: ItemCategory = .other,
        photoData: Data? = nil,
        tags: [String] = [],
        box: MovingBox? = nil
    ) {
        self.id = id
        self.name = name
        self.itemDescription = description
        self.categoryRaw = category.rawValue
        self.photoData = photoData
        self.tags = tags
        self.box = box
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    var category: ItemCategory {
        get { ItemCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue; updatedAt = Date() }
    }
}
