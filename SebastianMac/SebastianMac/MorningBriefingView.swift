import SwiftUI
import SwiftData

struct MorningBriefingView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(filter: #Predicate<TaskItem> { $0.statusValue != "done" }, sort: \.createdAt) private var allActiveTasks: [TaskItem]
    
    @AppStorage("lastBriefingDate") private var lastBriefingDate: String = ""
    
    var body: some View {
        let todayTasks = allActiveTasks.filter { isToday($0.dueDate) }.sorted { sortPriority($0, $1) }
        let soonTasks = allActiveTasks.filter { isWithinThreeDays($0.dueDate) && !isToday($0.dueDate) }.sorted {
            ($0.dueDate ?? Date.distantFuture) < ($1.dueDate ?? Date.distantFuture)
        }
        let highTasks = allActiveTasks.filter { $0.priorityValue == "high" && !isToday($0.dueDate) && !isWithinThreeDays($0.dueDate) }
        
        let hasTasks = !todayTasks.isEmpty || !soonTasks.isEmpty || !highTasks.isEmpty
        
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .top) {
                HStack(spacing: 12) {
                    // Bell icon
                    ZStack {
                        Circle()
                            .fill(Theme.goldAccent.opacity(0.1))
                            .frame(width: 36, height: 36)
                            .overlay(Circle().stroke(Theme.goldAccent.opacity(0.3), lineWidth: 1))
                        
                        Image(systemName: "bell.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Theme.goldAccent)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("おはようございます")
                            .font(Theme.Fonts.mincho(size: 18))
                            .foregroundColor(Theme.textPrimary)
                        Text("本日の状況をお知らせします")
                            .font(Theme.Fonts.mincho(size: 11))
                            .foregroundColor(Theme.textSecondary)
                    }
                }
                
                Spacer()
                
                Button(action: handleDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.textSecondary.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
            .padding(24)
            .background(Color.white.opacity(0.5))
            
            Divider().background(Color.gray.opacity(0.1))
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if !hasTasks {
                        VStack(spacing: 8) {
                            Text("本日期日・優先度の高いタスクはありません。")
                                .font(Theme.Fonts.mincho(size: 13))
                                .foregroundColor(Theme.textSecondary)
                            Text("良い1日を。")
                                .font(Theme.Fonts.mincho(size: 11))
                                .italic()
                                .foregroundColor(Theme.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    }
                    
                    if !todayTasks.isEmpty {
                        taskGroup(title: "今日が期日", tasks: todayTasks)
                    }
                    
                    if !soonTasks.isEmpty {
                        taskGroup(title: "3日以内が期日", tasks: soonTasks)
                    }
                    
                    if !highTasks.isEmpty {
                        taskGroup(title: "優先度が高いタスク", tasks: highTasks)
                    }
                }
                .padding(24)
            }
            .frame(maxHeight: 400)
            
            Divider().background(Color.gray.opacity(0.1))
            
            // Footer
            HStack {
                Button(action: handleDismiss) {
                    HStack(spacing: 4) {
                        Text("タスク一覧へ")
                        Image(systemName: "arrow.right")
                    }
                    .font(Theme.Fonts.mincho(size: 13))
                    .foregroundColor(Theme.textSecondary)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Button(action: handleDismiss) {
                    Text("確認しました")
                        .font(Theme.Fonts.mincho(size: 13))
                        .foregroundColor(Theme.buttonTextOnSidebar)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Theme.sidebarBackground)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
            .padding(20)
        }
        .frame(width: 480)
        .background(Theme.mainBackground)
        .overlay(
            ZStack {
                cornerOrnament()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(10)
                cornerOrnament()
                    .rotationEffect(.degrees(90))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(10)
                cornerOrnament()
                    .rotationEffect(.degrees(-90))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                    .padding(10)
                cornerOrnament()
                    .rotationEffect(.degrees(180))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .padding(10)
            }
            .border(Theme.goldAccent.opacity(0.3), width: 1)
        )
    }
    
    private func taskGroup(title: String, tasks: [TaskItem]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text(title)
                    .font(Theme.Fonts.mincho(size: 12))
                    .foregroundColor(Theme.textSecondary)
                
                Image(systemName: "diamond.fill")
                    .font(.system(size: 6))
                    .foregroundColor(Theme.goldAccent.opacity(0.6))
                
                Rectangle()
                    .fill(Theme.goldAccent.opacity(0.2))
                    .frame(height: 1)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(tasks) { task in
                    HStack(spacing: 8) {
                        let priorityStr = task.priorityValue == "high" ? "高" : (task.priorityValue == "low" ? "低" : (task.priorityValue == "medium" ? "中" : "なし"))
                        let prioColor = task.priorityValue == "high" ? Theme.priorityHigh : (task.priorityValue == "low" ? Theme.textSecondary : (task.priorityValue == "medium" ? Theme.priorityMedium : Theme.textSecondary.opacity(0.5)))
                        
                        if priorityStr != "なし" {
                            Text(priorityStr)
                                .font(Theme.Fonts.mincho(size: 10))
                                .foregroundColor(prioColor)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .overlay(RoundedRectangle(cornerRadius: 3).stroke(prioColor.opacity(0.3), lineWidth: 1))
                        } else {
                            Circle()
                                .fill(Theme.goldAccent.opacity(0.6))
                                .frame(width: 6, height: 6)
                        }
                        
                        Text(task.title)
                            .font(Theme.Fonts.mincho(size: 13))
                            .foregroundColor(Theme.textPrimary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        if let d = task.dueDate {
                            Text(formatDate(d))
                                .font(Theme.Fonts.mincho(size: 11))
                                .foregroundColor(Theme.textSecondary)
                        }
                    }
                }
            }
        }
    }
    
    private func cornerOrnament() -> some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 10))
            path.addLine(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 10, y: 0))
        }
        .stroke(Theme.goldAccent.opacity(0.4), lineWidth: 1)
        .frame(width: 10, height: 10)
    }
    
    private func handleDismiss() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        lastBriefingDate = formatter.string(from: Date())
        dismiss()
    }
    
    // Date Helpers
    private func isToday(_ date: Date?) -> Bool {
        guard let d = date else { return false }
        return Calendar.current.isDateInToday(d)
    }
    
    private func isWithinThreeDays(_ date: Date?) -> Bool {
        guard let d = date else { return false }
        let now = Date()
        guard let threeDaysLater = Calendar.current.date(byAdding: .day, value: 3, to: now) else { return false }
        return d > now && d <= threeDaysLater
    }
    
    private func sortPriority(_ a: TaskItem, _ b: TaskItem) -> Bool {
        let priorityMap = ["high": 3, "medium": 2, "low": 1, "none": 0]
        return (priorityMap[a.priorityValue] ?? 0) > (priorityMap[b.priorityValue] ?? 0)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }
}
