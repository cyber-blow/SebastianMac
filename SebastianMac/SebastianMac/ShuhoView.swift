import SwiftUI
import SwiftData

struct ShuhoView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WeeklyShuho.createdAt, order: .reverse) private var shuhos: [WeeklyShuho]
    @Query(sort: \DailyNippo.createdAt, order: .reverse) private var nippos: [DailyNippo]
    
    enum PageState { case idle, generating, draft, saving, saved }
    @State private var pageState: PageState = .idle
    
    @State private var draft: String = ""
    @State private var savedContent: String = ""
    @State private var errorMsg: String = ""
    
    @AppStorage("syncFolderPath") private var syncFolderPath: String = ""
    @AppStorage("useSlack") private var useSlack: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("WEEKLY REPORT")
                            .font(Theme.Fonts.cinzel(size: 12))
                            .foregroundColor(Theme.textSecondary)
                            .tracking(2)
                        
                        let today = Date()
                        let start = Calendar.current.date(byAdding: .day, value: -7, to: today) ?? today
                        Text("週報 — \(formatDateShort(start))〜\(formatDateShort(today))")
                            .font(Theme.Fonts.mincho(size: 28))
                            .foregroundColor(Theme.textPrimary)
                    }
                    Spacer()
                }
                .padding(.horizontal, 32)
                .padding(.top, 32)
                
                if !errorMsg.isEmpty {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text(errorMsg)
                            .font(.system(size: 13))
                            .foregroundColor(.red)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal, 32)
                }
                
                contentArea
                    .padding(.horizontal, 32)
                
                Spacer(minLength: 40)
            }
        }
        .onAppear {
            if let firstShuho = shuhos.first, Calendar.current.isDateInToday(firstShuho.createdAt) {
                savedContent = firstShuho.content
                pageState = .saved
            } else {
                pageState = .idle
            }
        }
    }
    
    @ViewBuilder
    private var contentArea: some View {
        switch pageState {
        case .idle:
            ornateCard {
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(Theme.goldAccent.opacity(0.1))
                            .frame(width: 56, height: 56)
                            .overlay(Circle().stroke(Theme.goldAccent.opacity(0.3), lineWidth: 1))
                        
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Theme.goldAccent)
                    }
                    
                    VStack(spacing: 8) {
                        Text("今週の振り返りを生成しますか？")
                            .font(Theme.Fonts.mincho(size: 20))
                            .foregroundColor(Theme.textPrimary)
                        
                        Text("過去7日間の日報を元に、セバスチャンが週報案を整えます。")
                            .font(Theme.Fonts.mincho(size: 14))
                            .foregroundColor(Theme.textSecondary)
                    }
                    
                    Button(action: { Task { await handleGenerate() } }) {
                        Text("週報案を生成する")
                            .font(Theme.Fonts.mincho(size: 14))
                            .foregroundColor(Theme.buttonTextOnSidebar)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 12)
                            .background(Theme.sidebarBackground)
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.goldAccent.opacity(0.3), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    
                    if !syncFolderPath.isEmpty {
                        Text("※ 設定されたフォルダへMarkdownファイルが保存されます")
                            .font(Theme.Fonts.mincho(size: 12))
                            .foregroundColor(Theme.textSecondary.opacity(0.6))
                    }
                }
                .padding(.vertical, 40)
            }
            
        case .generating:
            ornateCard {
                VStack(spacing: 16) {
                    ProgressView()
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .foregroundColor(Theme.goldAccent)
                        Text("セバスチャンが週報案を整えています...")
                            .font(Theme.Fonts.mincho(size: 14))
                            .foregroundColor(Theme.textSecondary)
                    }
                }
                .padding(.vertical, 60)
            }
            
        case .draft, .saving:
            VStack(spacing: 16) {
                HStack {
                    Text("内容をご確認・編集のうえ、承認してください。")
                        .font(Theme.Fonts.mincho(size: 14))
                        .foregroundColor(Theme.textSecondary)
                    Spacer()
                    Button(action: { Task { await handleGenerate() } }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.clockwise")
                            Text("再生成")
                        }
                        .font(Theme.Fonts.mincho(size: 12))
                        .foregroundColor(Theme.textSecondary)
                    }
                    .buttonStyle(.plain)
                    .disabled(pageState == .saving)
                }
                
                TextEditor(text: $draft)
                    .font(.system(size: 14, design: .monospaced))
                    .padding()
                    .frame(minHeight: 300)
                    .scrollContentBackground(.hidden)
                    .background(Theme.cardBackground)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.goldAccent.opacity(0.3), lineWidth: 1))
                    .disabled(pageState == .saving)
                
                HStack(spacing: 16) {
                    Button(action: { pageState = .idle; draft = "" }) {
                        Text("やり直す")
                            .font(Theme.Fonts.mincho(size: 14))
                            .foregroundColor(Theme.textSecondary)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .disabled(pageState == .saving)
                    
                    Button(action: { Task { await handleApprove() } }) {
                        Text(pageState == .saving ? "保存中..." : "承認・保存する")
                            .font(Theme.Fonts.mincho(size: 14))
                            .foregroundColor(Theme.buttonTextOnSidebar)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Theme.sidebarBackground)
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.goldAccent.opacity(0.3), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .disabled(pageState == .saving)
                }
            }
            
        case .saved:
            VStack(spacing: 24) {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("今週の週報は承認済みです")
                    }
                    .font(Theme.Fonts.mincho(size: 14))
                    .foregroundColor(.green)
                    
                    Spacer()
                    
                    Button(action: { pageState = .draft; draft = savedContent }) {
                        HStack(spacing: 4) {
                            Image(systemName: "pencil")
                            Text("再編集")
                        }
                        .font(Theme.Fonts.mincho(size: 12))
                        .foregroundColor(Theme.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
                
                ornateCard {
                    Text(savedContent)
                        .font(.system(size: 14))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func handleGenerate() async {
        pageState = .generating
        errorMsg = ""
        
        let cal = Calendar.current
        let today = Date()
        let sevenDaysAgo = cal.date(byAdding: .day, value: -7, to: today)!
        let recentNippos = nippos.filter { $0.createdAt >= sevenDaysAgo }
        
        let nippoTexts = recentNippos.map { $0.content }.joined(separator: "\n\n---\n\n")
        guard !nippoTexts.isEmpty else {
            errorMsg = "過去7日間の日報データがありません。"
            pageState = .idle
            return
        }
        
        do {
            let text = try await AIService.shared.generateNippo(from: ["以下の日報を元に1週間のまとめ(週報)を作成してください:\n" + nippoTexts], targetDate: today)
            await MainActor.run {
                draft = text
                pageState = .draft
            }
        } catch {
            await MainActor.run {
                errorMsg = "エラーが発生しました: \(error.localizedDescription)"
                pageState = .idle
            }
        }
    }
    
    private func handleApprove() async {
        pageState = .saving
        errorMsg = ""
        
        let contentToSave = draft
        let dateDash = formatDateDash(Date())
        
        let shuho = WeeklyShuho(content: contentToSave)
        shuho.createdAt = Date()
        modelContext.insert(shuho)
        
        do {
            try modelContext.save()
            
            if !syncFolderPath.isEmpty {
                let yyyymmdd = dateDash.replacingOccurrences(of: "-", with: "")
                let filename = "Shuho_\(yyyymmdd).md"
                let url = URL(fileURLWithPath: syncFolderPath).appendingPathComponent(filename)
                try contentToSave.write(to: url, atomically: true, encoding: .utf8)
            }
            
            await MainActor.run {
                savedContent = contentToSave
                draft = ""
                pageState = .saved
            }
        } catch {
            await MainActor.run {
                errorMsg = "保存に失敗しました: \(error.localizedDescription)"
                pageState = .draft
            }
        }
    }
    
    // MARK: - Views & Helpers
    
    private func ornateCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ZStack {
            Theme.cardBackground
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 10, y: 4)
            
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.goldAccent.opacity(0.3), lineWidth: 1)
            
            Group {
                cornerOrnament().frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading).padding(4)
                cornerOrnament().rotationEffect(.degrees(90)).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing).padding(4)
                cornerOrnament().rotationEffect(.degrees(-90)).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading).padding(4)
                cornerOrnament().rotationEffect(.degrees(180)).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing).padding(4)
            }
            
            content().frame(maxWidth: .infinity)
        }
    }
    
    private func cornerOrnament() -> some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 8))
            path.addLine(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 8, y: 0))
        }
        .stroke(Theme.goldAccent.opacity(0.4), lineWidth: 1)
        .frame(width: 8, height: 8)
    }
    
    private func formatDateShort(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "MM/dd"
        return f.string(from: date)
    }
    
    private func formatDateDash(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
}
