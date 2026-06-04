import UIKit

protocol AIProductRecognitionService {
    func analyzeProduct(image: UIImage) async throws -> ProductAnalysisResult
}

enum AIProductRecognitionError: LocalizedError {
    case missingAPIKey
    case invalidImage
    case invalidResponse
    case apiError(String)
    case analysisFailed

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Не найден OpenAI API key. Добавьте OPENAI_API_KEY в Info target."
        case .invalidImage:
            return "Не удалось подготовить фото для анализа."
        case .invalidResponse:
            return "OpenAI вернул ответ в неожиданном формате."
        case .apiError(let message):
            return message
        case .analysisFailed:
            return "Не удалось проанализировать фото. Попробуйте другое изображение."
        }
    }
}
