import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("anthropic_api_key") private var apiKey = ""
    @State private var draftKey = ""
    @State private var showKey = false
    @State private var saved = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundStyle(.blue)
                            Text("AI Object Recognition")
                                .font(.headline)
                        }
                        Text("Enter your Anthropic API key to enable automatic item identification when scanning photos.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Claude AI")
                }

                Section {
                    HStack {
                        Group {
                            if showKey {
                                TextField("sk-ant-...", text: $draftKey)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                            } else {
                                SecureField("sk-ant-...", text: $draftKey)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                            }
                        }
                        Button {
                            showKey.toggle()
                        } label: {
                            Image(systemName: showKey ? "eye.slash" : "eye")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }

                    if !apiKey.isEmpty {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("API key saved")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                    }

                    Button(action: saveKey) {
                        HStack {
                            Spacer()
                            if saved {
                                Label("Saved!", systemImage: "checkmark")
                            } else {
                                Text("Save API Key")
                            }
                            Spacer()
                        }
                    }
                    .disabled(draftKey.trimmingCharacters(in: .whitespaces).isEmpty)
                } header: {
                    Text("API Key")
                } footer: {
                    // swiftlint:disable line_length
                    Text("Get your free API key at console.anthropic.com. The key is stored securely on this device only.")
                }

                Section("How to get an API key") {
                    VStack(alignment: .leading, spacing: 8) {
                        step(number: "1", text: "Go to console.anthropic.com")
                        step(number: "2", text: "Sign up or log in")
                        step(number: "3", text: "Go to Settings → API Keys")
                        step(number: "4", text: "Click \"Create Key\" and copy it")
                        step(number: "5", text: "Paste it above and tap Save")
                    }
                    .padding(.vertical, 4)
                }

                if !apiKey.isEmpty {
                    Section {
                        Button("Remove API Key", role: .destructive) {
                            apiKey = ""
                            draftKey = ""
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                draftKey = apiKey
            }
        }
    }

    private func saveKey() {
        apiKey = draftKey.trimmingCharacters(in: .whitespaces)
        saved = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            saved = false
        }
    }

    private func step(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(number)
                .font(.caption).bold()
                .frame(width: 20, height: 20)
                .background(Color.blue.opacity(0.15))
                .foregroundStyle(.blue)
                .clipShape(Circle())
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
