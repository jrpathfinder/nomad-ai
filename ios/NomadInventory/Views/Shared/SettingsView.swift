import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var lang: LocalizationManager
    @AppStorage("anthropic_api_key") private var apiKey = ""
    @State private var draftKey = ""
    @State private var showKey = false
    @State private var saved = false
    @State private var isTesting = false
    @State private var testResult = ""

    var body: some View {
        NavigationStack {
            Form {
                // ── Language ─────────────────────────────────────────────────
                Section(lang.s(.languageSection)) {
                    Picker(lang.s(.languageLabel), selection: $lang.language) {
                        ForEach(AppLanguage.allCases) { language in
                            Text("\(language.flag) \(language.displayName)").tag(language)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // ── API Key ───────────────────────────────────────────────────
                Section {
                    HStack {
                        Group {
                            if showKey {
                                TextField(lang.s(.apiKeyPlaceholder), text: $draftKey)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                                    .font(.footnote)
                            } else {
                                SecureField(lang.s(.apiKeyPlaceholder), text: $draftKey)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                            }
                        }
                        Button { showKey.toggle() } label: {
                            Image(systemName: showKey ? "eye.slash" : "eye")
                                .foregroundStyle(.secondary)
                        }.buttonStyle(.plain)
                    }

                    Button(action: saveKey) {
                        HStack {
                            Spacer()
                            Label(saved ? lang.s(.saved) : lang.s(.saveApiKey),
                                  systemImage: saved ? "checkmark" : "square.and.arrow.down")
                            Spacer()
                        }
                    }
                    .disabled(draftKey.trimmingCharacters(in: .whitespaces).isEmpty)

                } header: {
                    Text(lang.s(.apiKeySection))
                } footer: {
                    if apiKey.isEmpty {
                        Text(lang.s(.noKeySaved)).foregroundStyle(.orange)
                    } else {
                        Text("\(lang.s(.keyStored)): \(maskedKey)").foregroundStyle(.green)
                    }
                }

                // ── Test ──────────────────────────────────────────────────────
                Section {
                    Button {
                        Task { await testKey() }
                    } label: {
                        HStack {
                            Spacer()
                            if isTesting {
                                ProgressView()
                                Text(lang.s(.testing)).padding(.leading, 6)
                            } else {
                                Label(lang.s(.testConnection), systemImage: "network")
                            }
                            Spacer()
                        }
                    }
                    .disabled(apiKey.isEmpty || isTesting)

                    if !testResult.isEmpty {
                        Text(testResult)
                            .font(.caption)
                            .foregroundStyle(testResult.hasPrefix("✅") ? .green : .red)
                            .padding(.vertical, 4)
                    }
                } header: {
                    Text(lang.s(.debugSection))
                }

                // ── Remove ────────────────────────────────────────────────────
                if !apiKey.isEmpty {
                    Section {
                        Button(lang.s(.removeApiKey), role: .destructive) {
                            apiKey = ""
                            draftKey = ""
                            testResult = ""
                        }
                    }
                }
            }
            .navigationTitle(lang.s(.settingsTitle))
            .onAppear { draftKey = apiKey }
        }
    }

    // MARK: - Helpers

    private var maskedKey: String {
        guard apiKey.count > 8 else { return "***" }
        return String(apiKey.prefix(8)) + "..." + String(apiKey.suffix(4))
    }

    private func saveKey() {
        apiKey = draftKey.trimmingCharacters(in: .whitespaces)
        saved = true
        testResult = ""
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { saved = false }
    }

    private func testKey() async {
        isTesting = true
        testResult = ""
        let body: [String: Any] = [
            "model": "claude-haiku-4-5-20251001",
            "max_tokens": 16,
            "messages": [["role": "user", "content": "Say OK"]]
        ]
        do {
            var req = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.setValue(apiKey, forHTTPHeaderField: "x-api-key")
            req.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
            req.httpBody = try JSONSerialization.data(withJSONObject: body)
            req.timeoutInterval = 15
            let (data, response) = try await URLSession.shared.data(for: req)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            let raw = String(data: data, encoding: .utf8) ?? "no body"
            testResult = status == 200 ? "✅ API key works! (HTTP \(status))" : "❌ HTTP \(status): \(raw)"
        } catch {
            testResult = "❌ \(error.localizedDescription)"
        }
        isTesting = false
    }
}
