import Foundation
import UIKit

struct MockAIProductRecognitionService: AIProductRecognitionService {
    func analyzeProduct(image: UIImage) async throws -> ProductAnalysisResult {
        try await Task.sleep(nanoseconds: 900_000_000)

        // TODO: Replace this mock with a real Vision/API request, for example OpenAI Vision API.
        return ProductAnalysisResult(
            productName: "Молочко",
            category: "Молочные продукты",
            estimatedExpiryDate: Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date(),
            confidence: 0.86
        )
    }
}
