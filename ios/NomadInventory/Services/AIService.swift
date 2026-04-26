import UIKit
import Foundation

struct IdentifiedItem {
    var name: String
    var description: String
    var suggestedCategory: ItemCategory
    var suggestedTags: [String]
    var confidence: Double
}

// Not @MainActor — heavy work runs on background threads.
// Only @Published updates are dispatched to main.
final class AIService: ObservableObject {
    @Published var isLoading = false
    @Published var lastError: String?

    private var apiKey: String {
        UserDefaults.standard.string(forKey: "anthropic_api_key") ?? ""
    }

    private let endpoint = "https://api.anthropic.com/v1/messages"
    private let model    = "claude-opus-4-6"

    func identify(image: UIImage) async -> IdentifiedItem? {
        let key = apiKey
        guard !key.isEmpty else {
            await setError("No API key — go to Settings and enter your Anthropic key.")
            return fallback()
        }

        await setLoading(true)
        defer { Task { await self.setLoading(false) } }

        // ── Encode image on a background thread ──────────────────────────────
        guard let base64 = await Task.detached(priority: .userInitiated) {
            Self.encodeImage(image)
        }.value else {
            await setError("Failed to encode image.")
            return fallback()
        }

        // ── Build request ─────────────────────────────────────────────────────
        let body: [String: Any] = [
            "model": model,
            "max_tokens": 512,
            "messages": [[
                "role": "user",
                "content": [
                    ["type": "image",
                     "source": ["type": "base64",
                                "media_type": "image/jpeg",
                                "data": base64]],
                    ["type": "text",
                     "text": """
                     You are an inventory assistant for home moving. \
                     Identify the main object in this image.
                     Respond ONLY with valid JSON, no markdown:
                     {
                       "name": "<short English object name>",
                       "description": "<one sentence>",
                       "category": "<one of: Electronics, Clothing, Kitchen, \
                     Furniture, Books, Documents, Tools, Toys, Sports, \
                     Bathroom, Bedroom, Decoration, Food, Other>",
                       "tags": ["tag1","tag2"],
                       "confidence": <0.0-1.0>
                     }
                     """]
                ]
            ]]
        ]

        // ── Network call (runs off main thread via async/await) ───────────────
        do {
            guard let bodyData = try? JSONSerialization.data(withJSONObject: body) else {
                await setError("Failed to build request.")
                return fallback()
            }

            var request = URLRequest(url: URL(string: endpoint)!)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(key, forHTTPHeaderField: "x-api-key")
            request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
            request.httpBody = bodyData
            request.timeoutInterval = 30

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let http = response as? HTTPURLResponse,
                  (200...299).contains(http.statusCode) else {
                let msg = String(data: data, encoding: .utf8) ?? "unknown error"
                await setError("API error: \(msg)")
                return fallback()
            }

            // ── Parse response on background thread ───────────────────────────
            let result = await Task.detached(priority: .userInitiated) {
                try? Self.parseResponse(data: data)
            }.value

            return result ?? fallback()

        } catch {
            await setError(error.localizedDescription)
            return fallback()
        }
    }

    // MARK: - Static helpers (safe to call from any thread)

    private static func encodeImage(_ image: UIImage) -> String? {
        let maxDim: CGFloat = 1024
        let scale = min(maxDim / image.size.width, maxDim / image.size.height, 1.0)
        let newSize = CGSize(width: image.size.width * scale,
                             height: image.size.height * scale)

        // UIGraphicsImageRenderer is thread-safe (unlike the legacy API)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        return resized.jpegData(compressionQuality: 0.8)?.base64EncodedString()
    }

    private static func parseResponse(data: Data) throws -> IdentifiedItem? {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = (json["content"] as? [[String: Any]])?.first,
              let text = content["text"] as? String
        else { return nil }

        var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("```") {
            cleaned = cleaned
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        guard let textData = cleaned.data(using: .utf8),
              let parsed = try JSONSerialization.jsonObject(with: textData) as? [String: Any]
        else { return nil }

        return IdentifiedItem(
            name:              parsed["name"]        as? String ?? "Unknown Item",
            description:      parsed["description"] as? String ?? "",
            suggestedCategory: ItemCategory(rawValue: parsed["category"] as? String ?? "Other")
                               ?? .other,
            suggestedTags:    parsed["tags"]        as? [String] ?? [],
            confidence:       parsed["confidence"]  as? Double   ?? 0.8
        )
    }

    // MARK: - Main-actor helpers

    @MainActor private func setLoading(_ value: Bool) { isLoading = value }
    @MainActor private func setError(_ msg: String)   { lastError = msg }

    private func fallback() -> IdentifiedItem {
        IdentifiedItem(name: "Unidentified Item",
                       description: lastError ?? "Please edit manually.",
                       suggestedCategory: .other,
                       suggestedTags: [],
                       confidence: 0.0)
    }
}
