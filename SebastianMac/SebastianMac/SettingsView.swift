import SwiftUI

struct SettingsView: View {
    @AppStorage("aiProvider") private var aiProvider: String = "gemini"
    @AppStorage("geminiAPIKey") private var geminiAPIKey: String = ""
    @AppStorage("geminiModel") private var geminiModel: String = "gemini-2.5-flash"
    @AppStorage("ollamaModel") private var ollamaModel: String = "llama3"
    
    @AppStorage("slackWebhookURL") private var slackWebhookURL: String = ""
    @AppStorage("isSlackEnabled") private var isSlackEnabled: Bool = false
    @AppStorage("userName") private var userName: String = ""
    
    @AppStorage("syncFolderPath") private var syncFolderPath: String = ""
    @AppStorage("weeklyFolderPath") private var weeklyFolderPath: String = "" // Added based on image
    
    @AppStorage("appTheme") private var appTheme: String = "sepia"
    
    @State private var showAPIKey = false
    @State private var availableModels: [String] = ["gemini-1.5-flash", "gemini-1.5-pro", "gemini-2.0-flash", "gemini-2.5-flash"]
    @State private var isFetchingModels: Bool = false
    @State private var fetchModelError: String? = nil
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text("SETTINGS")
                            .font(Theme.Fonts.cinzel(size: 14))
                            .foregroundColor(Theme.textSecondary)
                            .tracking(2.0)
                        
                        Image(systemName: "diamond.fill")
                            .font(.system(size: 6))
                            .foregroundColor(Theme.goldAccent)
                    }
                    
                    Text("設定")
                        .font(Theme.Fonts.mincho(size: 26))
                        .foregroundColor(Theme.textPrimary)
                }
                
                // AI Settings Section
                VStack(spacing: 0) {
                    SettingsSectionHeader(title: "AI設定")
                    
                    VStack(alignment: .leading, spacing: 24) {
                        // AI Provider
                        VStack(alignment: .leading, spacing: 12) {
                            Text("AIプロバイダー")
                                .font(Theme.Fonts.mincho(size: 14))
                                .foregroundColor(Theme.textSecondary)
                            
                            HStack(spacing: 12) {
                                ProviderCard(
                                    title: "Gemini API",
                                    subtitle: "無料・高速・推奨",
                                    isSelected: aiProvider == "gemini",
                                    action: { aiProvider = "gemini" }
                                )
                                ProviderCard(
                                    title: "Ollama",
                                    subtitle: "ローカルLLM",
                                    isSelected: aiProvider == "ollama",
                                    action: { aiProvider = "ollama" }
                                )
                                ProviderCard(
                                    title: "無効",
                                    subtitle: "AI機能をオフ",
                                    isSelected: aiProvider == "none",
                                    action: { aiProvider = "none" }
                                )
                            }
                        }
                        
                        // API Key
                        if aiProvider == "gemini" {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("APIキー")
                                    .font(Theme.Fonts.mincho(size: 14))
                                    .foregroundColor(Theme.textSecondary)
                                
                                HStack(spacing: 0) {
                                    if showAPIKey {
                                        TextField("AIzSy...", text: $geminiAPIKey)
                                            .font(Theme.Fonts.mincho(size: 14))
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 12)
                                    } else {
                                        SecureField("AIzSy...", text: $geminiAPIKey)
                                            .font(Theme.Fonts.mincho(size: 14))
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 12)
                                    }
                                    
                                    Button(action: { showAPIKey.toggle() }) {
                                        Image(systemName: showAPIKey ? "eye.slash" : "eye")
                                            .foregroundColor(Theme.textSecondary)
                                            .padding(.horizontal, 16)
                                            .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                }
                                .background(Theme.mainBackground)
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.15), lineWidth: 1))
                                
                                Text("取得先: https://aistudio.google.com/apikey (無料)")
                                    .font(.system(size: 10))
                                    .foregroundColor(Theme.textSecondary.opacity(0.8))
                            }
                            
                            // Model
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("モデル")
                                        .font(Theme.Fonts.mincho(size: 14))
                                        .foregroundColor(Theme.textSecondary)
                                    Spacer()
                                    if isFetchingModels {
                                        ProgressView().controlSize(.small)
                                    }
                                    Button(action: {
                                        Task { await fetchModels() }
                                    }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "arrow.triangle.2.circlepath")
                                            Text("更新")
                                        }
                                        .font(Theme.Fonts.mincho(size: 10))
                                    }
                                    .buttonStyle(.plain)
                                    .foregroundColor(Theme.goldAccent)
                                }
                                
                                Menu {
                                    ForEach(availableModels, id: \.self) { model in
                                        Button(model) {
                                            geminiModel = model
                                        }
                                    }
                                } label: {
                                    Text(geminiModel.isEmpty ? "モデルを選択" : geminiModel)
                                        .font(.system(size: 14))
                                        .foregroundColor(Theme.textPrimary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .menuStyle(.borderlessButton)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Theme.mainBackground)
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.15), lineWidth: 1))
                                
                                if let error = fetchModelError {
                                    Text(error)
                                        .font(.system(size: 10))
                                        .foregroundColor(.red)
                                } else {
                                    Text("推奨: gemini-1.5-flash (無料・高速)")
                                        .font(Theme.Fonts.mincho(size: 10))
                                        .foregroundColor(Theme.textSecondary.opacity(0.8))
                                }
                            }
                            .onAppear {
                                if !geminiAPIKey.isEmpty {
                                    Task { await fetchModels() }
                                }
                            }
                        } else if aiProvider == "ollama" {
                            // Ollama Model
                            VStack(alignment: .leading, spacing: 8) {
                                Text("モデル名")
                                    .font(Theme.Fonts.mincho(size: 14))
                                    .foregroundColor(Theme.textSecondary)
                                
                                TextField("llama3", text: $ollamaModel)
                                    .font(.system(size: 14))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(Theme.mainBackground)
                                    .cornerRadius(8)
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.15), lineWidth: 1))
                            }
                        }
                        
                        // Test Button
                        if aiProvider != "none" {
                            Button(action: {
                                // Connection Test dummy action
                            }) {
                                HStack {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                        .font(.system(size: 12))
                                    Text("接続テスト")
                                        .font(Theme.Fonts.mincho(size: 12))
                                }
                                .foregroundColor(Theme.textSecondary)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(Theme.mainBackground)
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.15), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(24)
                }
                .background(Theme.cardBackground)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.goldAccent.opacity(0.15), lineWidth: 1))
                
                // Report Storage Section
                VStack(spacing: 0) {
                    SettingsSectionHeader(title: "レポート保存先")
                    
                    VStack(alignment: .leading, spacing: 24) {
                        PathSelectorRow(title: "日報の保存フォルダ", pathString: $syncFolderPath)
                        PathSelectorRow(title: "週報の保存フォルダ", pathString: $weeklyFolderPath)
                    }
                    .padding(24)
                }
                .background(Theme.cardBackground)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.goldAccent.opacity(0.15), lineWidth: 1))
                
                // Slack Settings (Re-styled existing logic)
                VStack(spacing: 0) {
                    SettingsSectionHeader(title: "Slack・外部連携")
                    
                    VStack(alignment: .leading, spacing: 24) {
                        HStack {
                            Text("Slack通信の有効化")
                                .font(Theme.Fonts.mincho(size: 14))
                                .foregroundColor(Theme.textSecondary)
                            Spacer()
                            Toggle("", isOn: $isSlackEnabled)
                                .labelsHidden()
                                .toggleStyle(SwitchToggleStyle(tint: Color(hex: "6A9E75")))
                        }
                        
                        if isSlackEnabled {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("投稿者名 (任意)")
                                    .font(Theme.Fonts.mincho(size: 14))
                                    .foregroundColor(Theme.textSecondary)
                                TextField("Sebastian", text: $userName)
                                    .font(.system(size: 14))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(Theme.mainBackground)
                                    .cornerRadius(8)
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.15), lineWidth: 1))
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Webhook URL")
                                    .font(Theme.Fonts.mincho(size: 14))
                                    .foregroundColor(Theme.textSecondary)
                                TextField("https://hooks.slack.com/...", text: $slackWebhookURL)
                                    .font(.system(size: 14))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(Theme.mainBackground)
                                    .cornerRadius(8)
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.15), lineWidth: 1))
                            }
                        }
                    }
                    .padding(24)
                }
                .background(Theme.cardBackground)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.goldAccent.opacity(0.15), lineWidth: 1))
                
                // Operation Section
                VStack(spacing: 0) {
                    SettingsSectionHeader(title: "操作・起動")
                    
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("クイックメモショートカットキー")
                                .font(Theme.Fonts.mincho(size: 14))
                                .foregroundColor(Theme.textSecondary)
                            
                            HStack {
                                Text("Opt + Space (設定例)")
                                    .font(.system(size: 14))
                                    .foregroundColor(Theme.textPrimary)
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Theme.mainBackground)
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.15), lineWidth: 1))
                        }
                    }
                    .padding(24)
                }
                .background(Theme.cardBackground)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.goldAccent.opacity(0.15), lineWidth: 1))
                
                Spacer(minLength: 40)
            }
            .padding(40)
        }
    }

    private func fetchModels() async {
        guard !geminiAPIKey.isEmpty else { return }
        isFetchingModels = true
        fetchModelError = nil
        do {
            let models = try await AIService.shared.fetchAvailableModels()
            await MainActor.run {
                availableModels = models
                if !models.contains(geminiModel) && !models.isEmpty {
                    geminiModel = models.first!
                }
                isFetchingModels = false
            }
        } catch {
            await MainActor.run {
                fetchModelError = "モデル取得失敗: \(error.localizedDescription)"
                isFetchingModels = false
            }
        }
    }
}

// MARK: - Component UI

struct SettingsSectionHeader: View {
    let title: String
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Text(title)
                    .font(Theme.Fonts.mincho(size: 16))
                    .foregroundColor(Theme.textPrimary)
                
                Image(systemName: "diamond.fill")
                    .font(.system(size: 6))
                    .foregroundColor(Theme.goldAccent)
                
                Spacer()
            }
            .padding(24)
            
            Divider()
                .background(Color.gray.opacity(0.1))
        }
    }
}

struct ProviderCard: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(Theme.Fonts.mincho(size: 14))
                    .foregroundColor(isSelected ? Theme.textPrimary : Theme.textSecondary)
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundColor(Theme.textSecondary.opacity(0.8))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(isSelected ? Theme.goldAccent.opacity(0.05) : Theme.mainBackground)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Theme.goldAccent : Color.gray.opacity(0.15), lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct PathSelectorRow: View {
    let title: String
    @Binding var pathString: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(Theme.Fonts.mincho(size: 14))
                .foregroundColor(Theme.textSecondary)
            
            HStack(spacing: 0) {
                Text(pathString.isEmpty ? "フォルダを選択してください" : pathString)
                    .font(Theme.Fonts.mincho(size: 14))
                    .foregroundColor(pathString.isEmpty ? Theme.textSecondary.opacity(0.5) : Theme.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Divider()
                    .background(Color.gray.opacity(0.15))
                
                Button(action: {
                    // Open Folder Dialog
                    Task {
                        let panel = NSOpenPanel()
                        panel.canChooseDirectories = true
                        panel.canChooseFiles = false
                        panel.allowsMultipleSelection = false
                        if await panel.beginSheetModal(for: NSApp.keyWindow!) == .OK, let url = panel.url {
                            pathString = url.path
                        }
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "folder")
                            .font(.system(size: 12))
                        Text("参照")
                            .font(Theme.Fonts.mincho(size: 12))
                    }
                    .foregroundColor(Theme.textSecondary)
                    .padding(.horizontal, 16)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .background(Theme.mainBackground)
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.15), lineWidth: 1))
        }
    }

}