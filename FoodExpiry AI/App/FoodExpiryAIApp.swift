import SwiftData
import SwiftUI

@main
struct FoodExpiryAIApp: App {
    private let modelContainer: ModelContainer
    private let storageErrorMessage: String?

    init() {
        let configuration = ModelConfiguration(schema: Schema([Product.self]))

        do {
            modelContainer = try ModelContainer(for: Product.self, configurations: configuration)
            storageErrorMessage = nil
        } catch {
            let inMemoryConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
            modelContainer = try! ModelContainer(for: Product.self, configurations: inMemoryConfiguration)
            storageErrorMessage = "Не удалось открыть локальное хранилище. Данные временно не сохраняются: \(error.localizedDescription)"
        }
    }

    var body: some Scene {
        WindowGroup {
            ProductListView()
                .modelContainer(modelContainer)
                .overlay(alignment: .bottom) {
                    if let storageErrorMessage {
                        Text(storageErrorMessage)
                            .font(.caption)
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(.red.opacity(0.9), in: RoundedRectangle(cornerRadius: 8))
                            .padding()
                    }
                }
        }
    }
}
