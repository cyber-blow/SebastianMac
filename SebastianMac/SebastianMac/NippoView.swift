import SwiftUI
import SwiftData

struct NippoView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Memo> { !$0.isProcessed }) private var pendingMemos: [Memo]
    @Query(filter: #Predicate<TaskItem> { $0.statusValue != "done" }) private var activeTasks: [TaskItem]
    @Query(sort: \DailyNippo.createdAt, order: .reverse) private var nippos: [DailyNippo]
    
    enum PageState { case idle, generating, draft, saving, saved }
    enum CandidateState { case idle, extracting, ready, done }
    
    @State private var pageState: PageState = .idle
    @State private var candidateState: CandidateState = .idle
    
    @State private var draft: String = ""
    @State private var savedContent: String = ""
    @State private var errorMsg: String = ""
    @State private var targetDate = Date()
    @State private var candidates: [AIService.TaskCandidateData] = []
    
    @AppStorage("syncFolderPath") private var syncFolderPath: String = ""
    @AppStorage("useSlack") private var useSlack: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("DAILY REPORT")
                            .font(Theme.Fonts.cinzel(size: 12))
                            .foregroundColor(Theme.textSecondary)
                            .tracking(2)
                        
                        Text("日報 — \(formatDate(targetDate))")
                            .font(Theme.Fonts.mincho(size: 28))
                            .foregroundColor(Theme.textPrimary)
                    }
                    Spacer()
                    DatePicker("", selection: $targetDate, displayedComponents: [.date])
                        .labelsHidden()
                        .environment(\.locale, Locale(identifier: "ja_JP"))
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
                
                // Content based on PageState
                contentArea
                    .padding(.horizontal, 32)
                
                Spacer(minLength: 40)
            }
        }
        .onAppear {
            if let firstNippo = nippos.first, Calendar.current.isDateInToday(firstNippo.createdAt) {
                savedContent = firstNippo.content
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
                        
                        Image(systemName: "sparkles")
                            .font(.system(size: 24))
                            .foregroundColor(Theme.goldAccent)
                    }
                    
                    VStack(spacing: 8) {
                        Text("本日の業務を締めますか？")
                            .font(Theme.Fonts.mincho(size: 20))
                            .foregroundColor(Theme.textPrimary)
                        
                        Text("未処理のメモと現在のタスク状況から、セバスチャンが日報案を整えます。")
                            .font(Theme.Fonts.mincho(size: 14))
                            .foregroundColor(Theme.textSecondary)
                    }
                    
                    Button(action: { Task { await handleGenerate() } }) {
                        Text("日報案を生成する")
                            .font(Theme.Fonts.mincho(size: 14))
                            .foregroundColor(Theme.buttonTextOnSidebar)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 12)
                            .background(Theme.sidebarBackground)
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.goldAccent.opacity(0.3), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .disabled(pendingMemos.isEmpty)
                    .opacity(pendingMemos.isEmpty ? 0.5 : 1.0)
                    
                    if pendingMemos.isEmpty {
                        Text("本日未処理のメモがありません。")
                            .font(.system(size: 12))
                            .foregroundColor(.orange)
                    }
                    
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
                        Text("セバスチャンが日報案を整えています...")
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
                        Text("本日の日報は承認済みです")
                    }
                    .font(Theme.Fonts.mincho(size: 14))
                    .foregroundColor(.green)
                    
                    Spacer()
                    
                    Button(action: { pageState = .draft; draft = savedContent; candidateState = .idle }) {
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
                
                // Tasks Extraction Section
                ornateCard {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("メモからタスクを追加しますか？")
                                .font(Theme.Fonts.mincho(size: 16))
                                .foregroundColor(Theme.textPrimary)
                            
                            Spacer()
                            
                            if candidateState == .idle || candidateState == .done {
                                Button(action: { Task { await handleExtractCandidates() } }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "sparkles")
                                        Text(candidateState == .done ? "再度抽出する" : "タスク候補を抽出する")
                                    }
                                    .font(Theme.Fonts.mincho(size: 12))
                                    .foregroundColor(Theme.goldAccent)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        
                        Divider().background(Color.gray.opacity(0.1))
                        
                        if candidateState == .extracting {
                            HStack(spacing: 8) {
                                Image(systemName: "sparkles")
                                    .foregroundColor(Theme.goldAccent)
                                Text("セバスチャンがメモからタスク候補を抽出しています...")
                                    .font(Theme.Fonts.mincho(size: 14))
                                    .foregroundColor(Theme.textSecondary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Theme.goldAccent.opacity(0.05))
                            .cornerRadius(8)
                        } else if candidateState == .ready {
                            TaskCandidatesPanel(
                                candidates: candidates,
                                activeTasks: activeTasks,
                                onApplied: { candidateState = .done },
                                sourceDate: formatDateDash(targetDate)
                            )
                        }
                    }
                    .padding()
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func handleGenerate() async {
        pageState = .generating
        errorMsg = ""
        let memoTexts = pendingMemos.map { $0.content }
        do {
            let text = try await AIService.shared.generateNippo(from: memoTexts, targetDate: targetDate)
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
        let dateDash = formatDateDash(targetDate)
        
        // 1. Save to DB
        let nippo = DailyNippo(content: contentToSave)
        nippo.createdAt = targetDate
        modelContext.insert(nippo)
        
        // Mark memos as processed
        for memo in pendingMemos {
            memo.isProcessed = true
        }
        
        do {
            try modelContext.save()
            
            // 2. Export to MD file if syncFolderPath is set
            if !syncFolderPath.isEmpty {
                let yyyymmdd = dateDash.replacingOccurrences(of: "-", with: "")
                let filename = "Nippo_\(yyyymmdd).md"
                let url = URL(fileURLWithPath: syncFolderPath).appendingPathComponent(filename)
                try contentToSave.write(to: url, atomically: true, encoding: .utf8)
            }
            
            // 3. Post to Slack if enabled
            if useSlack {
                try? await SlackService.shared.postNippo(content: contentToSave)
            }
            
            await MainActor.run {
                savedContent = contentToSave
                draft = ""
                pageState = .saved
                candidateState = .idle
                candidates = []
            }
        } catch {
            await MainActor.run {
                errorMsg = "保存に失敗しました: \(error.localizedDescription)"
                pageState = .draft
            }
        }
    }
    
    private func handleExtractCandidates() async {
        candidateState = .extracting
        errorMsg = ""
        // Get today's processed memos content (simplest: use savedContent)
        do {
            let res = try await AIService.shared.extractTaskCandidates(memo: savedContent, tasks: activeTasks, todayDateString: formatDateDash(targetDate))
            await MainActor.run {
                candidates = res
                candidateState = .ready
            }
        } catch {
            await MainActor.run {
                errorMsg = "タスク抽出エラー: \(error.localizedDescription)"
                candidateState = .idle
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
            
            // Corner ornaments
            Group {
                cornerOrnament().frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading).padding(4)
                cornerOrnament().rotationEffect(.degrees(90)).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing).padding(4)
                cornerOrnament().rotationEffect(.degrees(-90)).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading).padding(4)
                cornerOrnament().rotationEffect(.degrees(180)).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing).padding(4)
            }
            
            content()
                .frame(maxWidth: .infinity)
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
    
    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "yyyy/MM/dd"
        return f.string(from: date)
    }
    
    private func formatDateDash(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
}
