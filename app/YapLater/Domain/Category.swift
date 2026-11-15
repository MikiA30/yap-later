import Foundation

/// The fixed category set. The model may only choose from these; anything else becomes `.other`.
enum Category: String, Codable, CaseIterable, Identifiable, Sendable {
    case groceries, dining, coffee, transport, shopping, bills, fun, health, other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .groceries: "Groceries"
        case .dining: "Dining"
        case .coffee: "Coffee"
        case .transport: "Transport"
        case .shopping: "Shopping"
        case .bills: "Bills"
        case .fun: "Fun"
        case .health: "Health"
        case .other: "Other"
        }
    }

    var symbol: String {
        switch self {
        case .groceries: "cart.fill"
        case .dining: "fork.knife"
        case .coffee: "cup.and.saucer.fill"
        case .transport: "car.fill"
        case .shopping: "bag.fill"
        case .bills: "doc.text.fill"
        case .fun: "party.popper.fill"
        case .health: "heart.fill"
        case .other: "square.grid.2x2.fill"
        }
    }
}
