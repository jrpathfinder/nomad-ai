import SwiftUI

struct SettingsView: View {
    @AppStorage("anthropic_api_key") private var apiKey = ""
    @State private var draftKey = ""
    @State private var showKey = false
    @State private var saved = false
    @State private var isTesting = false
    @State private var testResult = ""
    @State private var showTestResult = false

    var body: some View {
        NavigationStack {
            Form {
                // ── API Key input ────────────────────────────────────────────
                Section {
                    HStack {
                        Group {
                            if showKey {
                                TextField("sk-ant-...", text: $draftKey)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                                    .font(.footnote)
                            } else {
                                SecureField("sk-ant-...", text: $draftKey)
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
                            Label(saved ? "Saved!" : "Save API Key",
                                  systemImage: saved ? "checkmark" : "square.and.arrow.down")
                            Spacer()
                        }
                    }
                    .disabled(draftKey.trimmingCharacters(in: .whitespaces).isEmpty)

                } header: {
                    Text("Anthropic API Key")
                } footer: {
                    if apiKey.isEmpty {
                        Text("No key saved. Get one free at console.anthropic.com")
                            .foregroundStyle(.orange)
                    } else {
                        Text("Key saved: \(maskedKey)")
                            .foregroundStyle(.green)
                    }
                }

                // ── Test button ──────────────────────────────────────────────
                Section {
                    Button {
                        Task { await testKey() }
                    } label: {
                        HStack {
                            Spacer()
                            if isTesting {
                                ProgressView()
                                Text("Testing…").padding(.leading, 6)
                            } else {
                                Label("Test API Connection", systemImage: "network")
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
                    Text("Diagnostics")
                }

                // ── Key stored value debug ───────────────────────────────────
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Stored key length: \(apiKey.count) chars")
                            .font(.caption).foregroundStyle(.secondary)
                        Text("UserDefaults key: \"anthropic_api_key\"")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Debug Info")
                }

                // ── Remove ───────────────────────────────────────────────────
                if !apiKey.isEmpty {
                    Section {
                        Button("Remove API Key", role: .destructive) {
                            apiKey = ""
                            draftKey = ""
                            testResult = ""
                        }
                    }
                }
            }
            .navigationTitle("Settings")
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

    // Sends a minimal text-only request to verify the key works
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

            if status == 200 {
                testResult = "✅ API key works! (HTTP \(status))"
            } else {
                testResult = "❌ HTTP \(status): \(raw)"
            }
        } catch {
            testResult = "❌ Network error: \(error.localizedDescription)"
        }

        isTesting = false
    }
}
