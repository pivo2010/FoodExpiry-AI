import Foundation
import UIKit

struct OpenAIProductRecognitionService: AIProductRecognitionService {
    private let apiKey: String
    private let model: String
    private let session: URLSession

    init(
        apiKey: String? = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String,
        model: String = (Bundle.main.object(forInfoDictionaryKey: "OPENAI_MODEL") as? String) ?? "gpt-4.1-mini",
        session: URLSession = .shared
    ) {
        self.apiKey = apiKey?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        self.model = model
        self.session = session
    }

    func analyzeProduct(image: UIImage) async throws -> ProductAnalysisResult {
        guard !apiKey.isEmpty else {
            throw AIProductRecognitionError.missingAPIKey
        }

        guard let imageData = ImageStorageHelper.data(from: image, compressionQuality: 0.65) else {
            throw AIProductRecognitionError.invalidImage
        }

        let request = try makeRequest(imageData: imageData)
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIProductRecognitionError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw AIProductRecognitionError.apiError(try decodeAPIError(from: data))
        }

        let outputText = try decodeOutputText(from: data)
        guard let decodedResult = try? JSONDecoder().decode(
            OpenAIProductAnalysisPayload.self,
            from: Data(outputText.utf8)
        ) else {
            throw AIProductRecognitionError.invalidResponse
        }

        let shelfLifeDays = min(max(decodedResult.estimatedShelfLifeDays, 0), 365)
        let expiryDate = Calendar.current.date(byAdding: .day, value: shelfLifeDays, to: Date()) ?? Date()

        return ProductAnalysisResult(
            productName: decodedResult.productName,
            category: normalizedCategory(decodedResult.category),
            estimatedExpiryDate: expiryDate,
            confidence: min(max(decodedResult.confidence, 0), 1)
        )
    }

    private func makeRequest(imageData: Data) throws -> URLRequest {
        guard let url = URL(string: "https://api.openai.com/v1/responses") else {
            throw AIProductRecognitionError.invalidResponse
        }

        let imageURL = "data:image/jpeg;base64,\(imageData.base64EncodedString())"
        let categorySchemaValues = Product.categories
        let today = ISO8601DateFormatter().string(from: Date())

        let body: [String: Any] = [
            "model": model,
            "input": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "input_text",
                            "text": """
                            Ты анализируешь фото продукта или упаковки для iOS-приложения контроля сроков годности. Сегодня: \(today). Определи продукт, выбери одну категорию строго из списка и оцени срок годности в днях от сегодняшней даты. Если на упаковке видна дата, используй её. Если даты не видно, дай разумную оценку для закрытого продукта. Отвечай только структурированными данными по схеме.
                            """
                        ],
                        [
                            "type": "input_image",
                            "image_url": imageURL,
                            "detail": "low"
                        ]
                    ]
                ]
            ],
            "text": [
                "format": [
                    "type": "json_schema",
                    "name": "product_analysis",
                    "strict": true,
                    "schema": [
                        "type": "object",
                        "additionalProperties": false,
                        "properties": [
                            "productName": [
                                "type": "string",
                                "description": "Короткое русское название продукта."
                            ],
                            "category": [
                                "type": "string",
                                "enum": categorySchemaValues
                            ],
                            "estimatedShelfLifeDays": [
                                "type": "integer",
                                "description": "Оценка срока годности в днях от сегодняшней даты."
                            ],
                            "confidence": [
                                "type": "number"
                            ]
                        ],
                        "required": [
                            "productName",
                            "category",
                            "estimatedShelfLifeDays",
                            "confidence"
                        ]
                    ]
                ]
            ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 45
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }

    private func decodeOutputText(from data: Data) throws -> String {
        let response = try JSONDecoder().decode(OpenAIResponse.self, from: data)

        if let outputText = response.outputText, !outputText.isEmpty {
            return outputText
        }

        for output in response.output ?? [] {
            for content in output.content ?? [] {
                if let text = content.text, !text.isEmpty {
                    return text
                }
            }
        }

        throw AIProductRecognitionError.invalidResponse
    }

    private func decodeAPIError(from data: Data) throws -> String {
        if let errorResponse = try? JSONDecoder().decode(OpenAIErrorResponse.self, from: data) {
            return errorResponse.error.message
        }

        return "OpenAI API вернул ошибку."
    }

    private func normalizedCategory(_ category: String) -> String {
        Product.categories.contains(category) ? category : "Другое"
    }
}

private struct OpenAIProductAnalysisPayload: Decodable {
    let productName: String
    let category: String
    let estimatedShelfLifeDays: Int
    let confidence: Double
}

private struct OpenAIResponse: Decodable {
    let outputText: String?
    let output: [OpenAIOutput]?

    enum CodingKeys: String, CodingKey {
        case outputText = "output_text"
        case output
    }
}

private struct OpenAIOutput: Decodable {
    let content: [OpenAIContent]?
}

private struct OpenAIContent: Decodable {
    let text: String?
}

private struct OpenAIErrorResponse: Decodable {
    let error: OpenAIError
}

private struct OpenAIError: Decodable {
    let message: String
}
