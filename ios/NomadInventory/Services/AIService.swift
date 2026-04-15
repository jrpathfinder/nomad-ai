import UIKit
import Foundation

// Result from AI identification of a photographed object
struct IdentifiedItem {
    var name: String
    var description: String
    var suggestedCategory: ItemCategory
    var suggestedTags: [String]
    var confidence: Double   // 0.0 – 1.0
}

@MainActor
final class AIService: ObservableObject {
    @Published var isLoading = false
    @Published var lastError: String?

    // API key — read from UserDefaults (set via SettingsView), then Info.plist fallback
    private var apiKey: String {
        if let stored = UserDefaults.standard.string(forKey: "anthropic_api_key"), !stored.isEmpty {
            return stored
        }
        return Bundle.main.infoDictionary?["ANTHROPIC_API_KEY"] as? String ?? ""
    }

    private let endpoint = "https://api.anthropic.com/v1/messages"
    private let model = "claude-opus-4-6"

    // Identify an object from a UIImage using Claude Vision
    func identify(image: UIImage) async -> IdentifiedItem? {
        guard !apiKey.isEmpty else {
            lastError = "API key not configured. Add ANTHROPIC_API_KEY to Info.plist."
            return fallbackIdentification(image: image)
        }

        isLoading = true
        defer { isLoading = false }

        guard let base64 = encodeImage(image) else {
            lastError = "Failed to encode image."
            return nil
        }

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 512,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "image",
                            "source": [
                                "type": "base64",
                                "media_type": "image/jpeg",
                                "data": base64
                            ]
                        ],
                        [
                            "type": "text",
                            "text": """
                            You are an inventory assistant for home moving. \
                            Look at this image and identify the main object.

                            Respond in JSON with exactly these fields:
                            {
                              "name": "<short object name, in English>",
                              "description": "<one sentence description>",
                              "category": "<one of: Electronics, Clothing, Kitchen, Furniture, Books, Documents, Tools, Toys, Sports, Bathroom, Bedroom, Decoration, Food, Other>",
                              "tags": ["tag1", "tag2"],
                              "confidence": <0.0-1.0>
                            }

                            Return only valid JSON, no markdown.
                            """
                        ]
                    ]
                ]
            ]
        ]

        do {
            var request = URLRequest(url: URL(string: endpoint)!)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
            request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            request.timeoutInterval = 30

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                let errBody = String(data: data, encoding: .utf8) ?? "unknown"
                lastError = "API error: \(errBody)"
                return fallbackIdentification(image: image)
            }

            return try parseResponse(data: data)

        } catch {
            lastError = error.localizedDescription
            return fallbackIdentification(image: image)
        }
    }

    // MARK: - Private helpers

    private func encodeImage(_ image: UIImage) -> String? {
        // Resize to max 1024px on longest side to keep payload small
        let maxDimension: CGFloat = 1024
        let scale = min(maxDimension / image.size.width, maxDimension / image.size.height, 1.0)
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return (resized ?? image).jpegData(compressionQuality: 0.8)?.base64EncodedString()
    }

    private func parseResponse(data: Data) throws -> IdentifiedItem? {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = (json["content"] as? [[String: Any]])?.first,
              let text = content["text"] as? String,
              let textData = text.data(using: .utf8),
              let parsed = try JSONSerialization.jsonObject(with: textData) as? [String: Any]
        else { return nil }

        let name = parsed["name"] as? String ?? "Unknown Item"
        let description = parsed["description"] as? String ?? ""
        let categoryStr = parsed["category"] as? String ?? "Other"
        let tags = parsed["tags"] as? [String] ?? []
        let confidence = parsed["confidence"] as? Double ?? 0.8

        return IdentifiedItem(
            name: name,
            description: description,
            suggestedCategory: ItemCategory(rawValue: categoryStr) ?? .suggest(for: name),
            suggestedTags: tags,
            confidence: confidence
        )
    }

    // Fallback when no API key or network failure — uses Vision framework heuristics
    private func fallbackIdentification(image: UIImage) -> IdentifiedItem {
        return IdentifiedItem(
            name: "Unidentified Item",
            description: "Please edit the name and category manually.",
            suggestedCategory: .other,
            suggestedTags: [],
            confidence: 0.0
        )
    }
}
