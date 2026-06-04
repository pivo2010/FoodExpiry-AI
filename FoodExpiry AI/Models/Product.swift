import Foundation
import SwiftData
import SwiftUI

@Model
final class Product {
    var id: UUID
    var name: String
    var category: String
    @Attribute(.externalStorage) var imageData: Data?
    var dateAdded: Date
    var expiryDate: Date
    var aiConfidence: Double?
    var notes: String?

    init(
        id: UUID = UUID(),
        name: String,
        category: String,
        imageData: Data? = nil,
        dateAdded: Date = Date(),
        expiryDate: Date,
        aiConfidence: Double? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.imageData = imageData
        self.dateAdded = dateAdded
        self.expiryDate = expiryDate
        self.aiConfidence = aiConfidence
        self.notes = notes
    }

    var daysUntilExpiry: Int {
        Calendar.current.dateComponents(
            [.day],
            from: Calendar.current.startOfDay(for: Date()),
            to: Calendar.current.startOfDay(for: expiryDate)
        ).day ?? 0
    }

    var expiryStatus: ExpiryStatus {
        if daysUntilExpiry < 0 {
            return .expired
        }

        if daysUntilExpiry <= 3 {
            return .expiringSoon
        }

        return .fresh
    }

    var statusColor: Color {
        expiryStatus.color
    }
}

extension Product {
    static let categories = [
        "Молочные продукты",
        "Мясо",
        "Рыба",
        "Овощи",
        "Фрукты",
        "Напитки",
        "Консервы",
        "Заморозка",
        "Хлеб и выпечка",
        "Другое"
    ]
}
