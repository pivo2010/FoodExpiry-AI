import SwiftUI

enum ExpiryStatus: String, CaseIterable, Identifiable, Codable {
    case fresh = "Свежий"
    case expiringSoon = "Скоро истечёт"
    case expired = "Просрочен"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .fresh:
            return .green
        case .expiringSoon:
            return .yellow
        case .expired:
            return .red
        }
    }

    var systemImage: String {
        switch self {
        case .fresh:
            return "checkmark.circle.fill"
        case .expiringSoon:
            return "clock.fill"
        case .expired:
            return "exclamationmark.triangle.fill"
        }
    }
}

enum ProductStatusFilter: String, CaseIterable, Identifiable {
    case all = "Все"
    case fresh = "Свежие"
    case expiringSoon = "Скоро истекают"
    case expired = "Просроченные"

    var id: String { rawValue }

    var expiryStatus: ExpiryStatus? {
        switch self {
        case .all:
            return nil
        case .fresh:
            return .fresh
        case .expiringSoon:
            return .expiringSoon
        case .expired:
            return .expired
        }
    }
}
