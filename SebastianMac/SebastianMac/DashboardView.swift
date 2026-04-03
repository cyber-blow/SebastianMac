import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    
    // 実際のデータを取得
    @Query(filter: #Predicate<TaskItem> { $0.statusValue != "done" }) private var uncompletedTasks: [TaskItem]
    @Query private var allTasks: [TaskItem]
    @Query(filter: #Predicate<Memo> { !$0.isProcessed }) private var pendingMemos: [Memo]
    @Query(sort: \DailyNippo.createdAt, order: .reverse) private var nippos: [DailyNippo]
    
    // Viewの状態
    @State private var currentDateString: String = ""
    
    var body: some View {
        let cal = Calendar.current
        let todayTasks = uncompletedTasks.filter { $0.dueDate != nil && cal.isDateInToday($0.dueDate!) }
        let highPriorityTasks = uncompletedTasks.filter { $0.priorityValue == "high" }
        
        let categoryDict = Dictionary(grouping: allTasks, by: { $0.category ?? "未分類" })
        let sortedCategories = categoryDict.keys.sorted { categoryDict[$0]!.count > categoryDict[$1]!.count }.prefix(8)
        
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                
                // ヘッダー周り
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("DASHBOARD")
                            .font(Theme.Fonts.cinzel(size: 14))
                            .foregroundColor(Theme.textSecondary)
                            .tracking(2.0)
                        
                        Spacer()
                    }
                    
                    Text("お疲れ様です、\(currentDateString) の状況です。")
                        .font(Theme.Fonts.mincho(size: 26))
                        .foregroundColor(Theme.textPrimary)
                }
                
                // 3つのKPIカード
                HStack(spacing: 24) {
                    KpiCard(
                        title: "未完了タスク",
                        value: "\(uncompletedTasks.count)",
                        unit: "件",
                        footer: nil
                    )
                    
                    KpiCard(
                        title: "本日のメモ",
                        value: "\(pendingMemos.reduce(0) { $0 + $1.content.count })",
                        unit: "文字",
                        footer: nil
                    )
                    
                    KpiCard(
                        title: "本日の日報",
                        value: (nippos.first != nil && cal.isDateInToday(nippos.first!.createdAt)) ? "◆ 作成済" : "未作成",
                        unit: "",
                        footer: "内容を確認する →"
                    )
                }
                
                // 2カラム (今日が期日 / 優先度が高い)
                HStack(alignment: .top, spacing: 24) {
                    // 左カラム
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeaderWithAction(title: "今日が期日のタスク", actionTitle: "すべて →")
                        if todayTasks.isEmpty {
                            Text("本日期日のタスクはありません")
                                .font(.system(size: 12))
                                .foregroundColor(Theme.textSecondary.opacity(0.6))
                                .italic()
                        } else {
                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(todayTasks) { task in
                                    ActionableTaskRow(task: task)
                                }
                            }
                        }
                        Spacer()
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.cardBackground)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.goldAccent.opacity(0.15), lineWidth: 1))
                    
                    // 右カラム
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeaderWithAction(title: "優先度が高いタスク", actionTitle: "すべて →")
                        if highPriorityTasks.isEmpty {
                            Text("優先度が高いタスクはありません")
                                .font(.system(size: 12))
                                .foregroundColor(Theme.textSecondary.opacity(0.6))
                                .italic()
                        } else {
                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(highPriorityTasks) { task in
                                    ActionableTaskRow(task: task)
                                }
                            }
                        }
                        Spacer()
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.cardBackground)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.goldAccent.opacity(0.15), lineWidth: 1))
                }
                
                // カテゴリ別サマリ
                if !sortedCategories.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(title: "カテゴリ別サマリ")
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            ForEach(sortedCategories, id: \.self) { cat in
                                let tasksInCat = categoryDict[cat]!
                                let doneCount = tasksInCat.filter { $0.statusValue == "done" }.count
                                CategoryProgressCard(title: cat, current: doneCount, total: tasksInCat.count)
                            }
                        }
                    }
                    .padding(24)
                    .background(Theme.cardBackground)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.goldAccent.opacity(0.15), lineWidth: 1))
                }
                
                Spacer(minLength: 40)
            }
            .padding(40)
        }
        .onAppear {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "ja_JP")
            formatter.dateFormat = "M月d日（E）"
            currentDateString = formatter.string(from: Date())
        }
    }
}

// MARK: - Components

struct KpiCard: View {
    let title: String
    let value: String
    let unit: String
    let footer: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(Theme.Fonts.mincho(size: 12))
                .foregroundColor(Theme.textSecondary)
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                if value.starts(with: "◆") {
                    Text(value)
                        .font(Theme.Fonts.mincho(size: 22))
                        .foregroundColor(Theme.textPrimary)
                } else {
                    Text(value)
                        .font(Theme.Fonts.cinzel(size: 32))
                        .foregroundColor(Theme.textPrimary)
                }
                
                if !unit.isEmpty {
                    Text(unit)
                        .font(Theme.Fonts.mincho(size: 14))
                        .foregroundColor(Theme.textSecondary)
                }
            }
            
            if let footer = footer {
                Text(footer)
                    .font(Theme.Fonts.mincho(size: 11))
                    .foregroundColor(Theme.textSecondary.opacity(0.6))
            } else {
                Spacer().frame(height: 11)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.goldAccent.opacity(0.15), lineWidth: 1)
        )
    }
}

struct SectionHeader: View {
    let title: String
    var icon: String? = nil
    
    var body: some View {
        HStack(spacing: 8) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textPrimary)
            }
            Text("\(title) ◆")
                .font(Theme.Fonts.mincho(size: 14))
                .foregroundColor(Theme.textPrimary)
        }
        .padding(.bottom, 8)
    }
}

struct SectionHeaderWithAction: View {
    let title: String
    let actionTitle: String
    
    var body: some View {
        HStack {
            Text("\(title) ◆")
                .font(Theme.Fonts.mincho(size: 14))
                .foregroundColor(Theme.textPrimary)
            
            Spacer()
            
            Text(actionTitle)
                .font(Theme.Fonts.mincho(size: 11))
                .foregroundColor(Theme.textSecondary.opacity(0.6))
        }
        .padding(.bottom, 8)
    }
}

struct ActionableTaskRow: View {
    let task: TaskItem
    
    var body: some View {
        HStack(spacing: 12) {
            let prioStr = task.priorityValue == "high" ? "高" : (task.priorityValue == "low" ? "低" : "中")
            let prioColor = task.priorityValue == "high" ? Theme.priorityHigh : Theme.textSecondary
            
            if task.priorityValue != "none" {
                Text(prioStr)
                    .font(Theme.Fonts.mincho(size: 12))
                    .foregroundColor(prioColor)
            } else {
                Text("—")
                    .font(Theme.Fonts.mincho(size: 12))
                    .foregroundColor(Theme.textSecondary)
            }
            
            Text(task.title)
                .font(Theme.Fonts.mincho(size: 14))
                .foregroundColor(Theme.textPrimary)
            
            Spacer()
            
            if let date = task.dueDate {
                let formatter = DateFormatter()
                formatter.dateFormat = "M/d"
                Text(formatter.string(from: date))
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textSecondary.opacity(0.5))
            }
        }
    }
}

struct CategoryProgressCard: View {
    let title: String
    let current: Int
    let total: Int
    
    var progress: Double {
        if total == 0 { return 0 }
        return Double(current) / Double(total)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(Theme.Fonts.mincho(size: 12))
                .foregroundColor(Theme.textPrimary)
            
            HStack {
                Text("\(current)/\(total)")
                    .font(.system(size: 10))
                    .foregroundColor(Theme.textSecondary)
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 10))
                    .foregroundColor(Theme.textSecondary)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Theme.goldAccent.opacity(0.2))
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    Rectangle()
                        .fill(Theme.goldAccent)
                        .frame(width: geo.size.width * CGFloat(progress), height: 4)
                        .cornerRadius(2)
                }
            }
            .frame(height: 4)
        }
        .padding(16)
        .background(Theme.cardBackground.opacity(0.5))
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.goldAccent.opacity(0.1), lineWidth: 1))
    }
}
