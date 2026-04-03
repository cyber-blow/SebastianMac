import SwiftUI
import SwiftData

struct MemoView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Memo.createdAt, order: .reverse) private var allMemos: [Memo]
    
    @State private var memoText: String = ""
    @State private var todayMemo: Memo?
    @State private var currentDateString: String = ""
    
    // 文字数カウント
    var characterCount: Int {
        memoText.count
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                
                // ヘッダー周り
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("MEMO")
                            .font(Theme.Fonts.cinzel(size: 14))
                            .foregroundColor(Theme.textSecondary)
                            .tracking(2.0)
                        
                        Text("本日の記録 (\(currentDateString))")
                            .font(Theme.Fonts.mincho(size: 26))
                            .foregroundColor(Theme.textPrimary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("保存済")
                            .font(Theme.Fonts.mincho(size: 14))
                            .foregroundColor(Theme.statusDone)
                        
                        Text("\(characterCount) 文字")
                            .font(Theme.Fonts.mincho(size: 12))
                            .foregroundColor(Theme.textSecondary)
                    }
                    .padding(.bottom, 4)
                }
                
                // 大きなエディタエリア
                TextEditor(text: $memoText)
                    .font(Theme.Fonts.mincho(size: 14))
                    .foregroundColor(Theme.textPrimary)
                    .padding(24)
                    .frame(minHeight: 500) // 画面いっぱいに広がるように高さを確保
                    .background(Theme.cardBackground)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                    )
                    .onChange(of: memoText) { oldValue, newValue in
                        saveMemo()
                    }
                
                Spacer(minLength: 40)
            }
            .padding(40)
        }
        .onAppear {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "ja_JP")
            formatter.dateFormat = "yyyy-MM-dd"
            currentDateString = formatter.string(from: Date())
            loadTodayMemo()
        }
    }
    
    // 本日のメモを読み込むか、無ければ作成する
    private func loadTodayMemo() {
        let calendar = Calendar.current
        let today = Date()
        
        // 未処理のメモのうち、今日作成されたものを探す
        if let existing = allMemos.first(where: { !$0.isProcessed && calendar.isDate($0.createdAt, inSameDayAs: today) }) {
            todayMemo = existing
            memoText = existing.content
        } else {
            // 見つからなければ新規作成（DB保存は入力時）
            memoText = ""
        }
    }
    
    // 入力されるたびに自動保存
    private func saveMemo() {
        if let memo = todayMemo {
            memo.content = memoText
        } else {
            let newMemo = Memo(content: memoText)
            modelContext.insert(newMemo)
            todayMemo = newMemo
        }
        try? modelContext.save()
    }
}
