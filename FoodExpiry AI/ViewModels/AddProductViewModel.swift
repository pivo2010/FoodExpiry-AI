import Combine
import Foundation
import UIKit

@MainActor
final class AddProductViewModel: ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var productName = ""
    @Published var category = Product.categories.first ?? "Другое"
    @Published var expiryDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @Published var notes = ""
    @Published var aiConfidence: Double?
    @Published var isAnalyzing = false
    @Published var errorMessage: String?

    private let recognitionService: AIProductRecognitionService

    init(recognitionService: AIProductRecognitionService? = nil) {
        self.recognitionService = recognitionService ?? MockAIProductRecognitionService()

        // Для подключения реального OpenAI API замените строку выше на:
        // self.recognitionService = recognitionService ?? OpenAIProductRecognitionService()
    }

    var canAnalyze: Bool {
        selectedImage != nil && !isAnalyzing
    }

    var canSave: Bool {
        !productName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func analyzeSelectedImage() async {
        guard let selectedImage else { return }

        isAnalyzing = true
        errorMessage = nil

        do {
            let result = try await recognitionService.analyzeProduct(image: selectedImage)
            productName = result.productName
            category = result.category
            expiryDate = result.estimatedExpiryDate
            aiConfidence = result.confidence
        } catch {
            errorMessage = error.localizedDescription
        }

        isAnalyzing = false
    }

    func makeProduct() -> Product? {
        let trimmedName = productName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return nil }

        return Product(
            name: trimmedName,
            category: category,
            imageData: selectedImage.flatMap { ImageStorageHelper.data(from: $0) },
            expiryDate: expiryDate,
            aiConfidence: aiConfidence,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes
        )
    }
}
