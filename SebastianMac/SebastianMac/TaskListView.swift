import SwiftUI
import SwiftData

struct TaskListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskItem.createdAt, order: .reverse) private var tasks: [TaskItem]
    
    @State private var filterMode: String = "すべて"
    @State private var showAddTaskSheet = false
    @State private var selectedTask: TaskItem?
    
    var filteredTasks: [TaskItem] {
        switch filterMode {
        case "未着手": return tasks.filter { $0.status == .todo }
        case "進行中": return tasks.filter { $0.status == .inProgress }
        case "保留": return tasks.filter { $0.status == .pending }
        case "完了": return tasks.filter { $0.status == .done }
        default: return tasks
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                
                // ヘッダー周り
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Text("TASKS")
                                .font(Theme.Fonts.cinzel(size: 14))
                                .foregroundColor(Theme.textSecondary)
                                .tracking(2.0)
                            
                            Image(systemName: "diamond.fill")
                                .font(.system(size: 6))
                                .foregroundColor(Theme.goldAccent)
                        }
                        
                        Text("タスク一覧")
                            .font(Theme.Fonts.mincho(size: 26))
                            .foregroundColor(Theme.textPrimary)
                    }
                    
                    Spacer()
                    
                    Button(action: { showAddTaskSheet = true }) {
                        HStack {
                            Image(systemName: "plus")
                            Text("タスクを追加")
                                .font(Theme.Fonts.mincho(size: 14))
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        .background(Theme.sidebarBackground)
                        .foregroundColor(Theme.buttonTextOnSidebar)
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
                
                // フィルタータブ
                HStack(spacing: 0) {
                    FilterTab(title: "すべて", filterMode: $filterMode)
                    FilterTab(title: "未着手", filterMode: $filterMode)
                    FilterTab(title: "進行中", filterMode: $filterMode)
                    FilterTab(title: "保留", filterMode: $filterMode)
                    FilterTab(title: "完了", filterMode: $filterMode)
                }
                .padding(4)
                .background(Theme.cardBackground.opacity(0.5))
                .cornerRadius(20)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.gray.opacity(0.1), lineWidth: 1))
                .padding(.bottom, 8)
                
                // タスクリスト (一枚のカード型コンテナ)
                if filteredTasks.isEmpty {
                    VStack {
                        Spacer()
                        Text("タスクがありません。")
                            .font(Theme.Fonts.mincho(size: 14))
                            .foregroundColor(Theme.textSecondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                    .background(Theme.cardBackground)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.goldAccent.opacity(0.15), lineWidth: 1))
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(filteredTasks.enumerated()), id: \.element.id) { index, task in
                            let isLast = index == filteredTasks.count - 1
                            TaskRowView(task: task, isLast: isLast, onEdit: {
                                selectedTask = task
                            }, onTapToggle: {
                                // 状態トグル: 未完了なら完了へ、完了なら未着手へ
                                task.status = task.status == .done ? .todo : .done
                                try? modelContext.save()
                            })
                        }
                    }
                    .background(Theme.cardBackground)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.goldAccent.opacity(0.15), lineWidth: 1))
                }
                
                // アーカイブセクション
                HStack(spacing: 8) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10))
                    Image(systemName: "archivebox")
                        .font(.system(size: 12))
                    Text("アーカイブ済み (\(tasks.filter { $0.status == .done }.count)件)")
                        .font(Theme.Fonts.mincho(size: 12))
                }
                .foregroundColor(Theme.textSecondary.opacity(0.6))
                .padding(.top, 8)
                
                Spacer(minLength: 40)
            }
            .padding(40)
        }
        .sheet(isPresented: $showAddTaskSheet) {
            AddTaskSheetView()
        }
        .sheet(item: $selectedTask) { task in
            EditTaskSheetView(task: task)
        }
    }
}

// MARK: - Components

struct FilterTab: View {
    let title: String
    @Binding var filterMode: String
    
    var isSelected: Bool { filterMode == title }
    
    var body: some View {
        Button(action: { filterMode = title }) {
            Text(title)
                .font(Theme.Fonts.mincho(size: 12))
                .foregroundColor(isSelected ? Theme.textPrimary : Theme.textSecondary.opacity(0.6))
                .padding(.vertical, 8)
                .padding(.horizontal, 20)
                .background(isSelected ? Theme.cardBackground : Color.clear)
                .cornerRadius(16)
                .shadow(color: isSelected ? Color.black.opacity(0.05) : Color.clear, radius: 2, y: 1)
        }
        .buttonStyle(.plain)
    }
}
