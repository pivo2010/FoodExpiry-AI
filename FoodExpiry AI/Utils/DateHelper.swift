import Foundation

enum DateHelper {
    static let displayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    static func displayDate(_ date: Date) -> String {
        displayFormatter.string(from: date)
    }

    static func daysText(_ days: Int) -> String {
        if days < 0 {
            return "Просрочен на \(abs(days)) дн."
        }

        if days == 0 {
            return "Истекает сегодня"
        }

        return "Осталось \(days) дн."
    }
}
