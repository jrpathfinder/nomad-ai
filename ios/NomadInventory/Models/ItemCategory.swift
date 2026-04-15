import Foundation
import SwiftUI

enum ItemCategory: String, CaseIterable, Codable, Identifiable {
    case electronics = "Electronics"
    case clothing = "Clothing"
    case kitchen = "Kitchen"
    case furniture = "Furniture"
    case books = "Books"
    case documents = "Documents"
    case tools = "Tools"
    case toys = "Toys"
    case sports = "Sports"
    case bathroom = "Bathroom"
    case bedroom = "Bedroom"
    case decoration = "Decoration"
    case food = "Food"
    case other = "Other"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .electronics: return "laptopcomputer"
        case .clothing: return "tshirt"
        case .kitchen: return "fork.knife"
        case .furniture: return "sofa"
        case .books: return "books.vertical"
        case .documents: return "doc.text"
        case .tools: return "wrench.and.screwdriver"
        case .toys: return "gamecontroller"
        case .sports: return "sportscourt"
        case .bathroom: return "shower"
        case .bedroom: return "bed.double"
        case .decoration: return "photo.artframe"
        case .food: return "cart"
        case .other: return "archivebox"
        }
    }

    var color: Color {
        switch self {
        case .electronics: return .blue
        case .clothing: return .purple
        case .kitchen: return .orange
        case .furniture: return .brown
        case .books: return .indigo
        case .documents: return .gray
        case .tools: return .red
        case .toys: return .yellow
        case .sports: return .green
        case .bathroom: return .cyan
        case .bedroom: return .mint
        case .decoration: return .pink
        case .food: return .teal
        case .other: return .secondary
        }
    }

    // AI-assisted category suggestion based on identified object name
    static func suggest(for objectName: String) -> ItemCategory {
        let name = objectName.lowercased()
        if name.contains("laptop") || name.contains("phone") || name.contains("tablet")
            || name.contains("computer") || name.contains("tv") || name.contains("cable")
            || name.contains("charger") || name.contains("camera") || name.contains("speaker") {
            return .electronics
        }
        if name.contains("shirt") || name.contains("pants") || name.contains("dress")
            || name.contains("jacket") || name.contains("shoes") || name.contains("hat")
            || name.contains("coat") || name.contains("sock") || name.contains("underwear") {
            return .clothing
        }
        if name.contains("plate") || name.contains("cup") || name.contains("pan")
            || name.contains("pot") || name.contains("knife") || name.contains("fork")
            || name.contains("spoon") || name.contains("bowl") || name.contains("glass") {
            return .kitchen
        }
        if name.contains("chair") || name.contains("table") || name.contains("sofa")
            || name.contains("bed") || name.contains("desk") || name.contains("shelf") {
            return .furniture
        }
        if name.contains("book") || name.contains("novel") || name.contains("magazine") {
            return .books
        }
        if name.contains("tool") || name.contains("hammer") || name.contains("drill")
            || name.contains("screwdriver") || name.contains("wrench") {
            return .tools
        }
        if name.contains("toy") || name.contains("game") || name.contains("puzzle")
            || name.contains("lego") || name.contains("doll") {
            return .toys
        }
        if name.contains("document") || name.contains("passport") || name.contains("certificate")
            || name.contains("paper") || name.contains("folder") {
            return .documents
        }
        return .other
    }
}
