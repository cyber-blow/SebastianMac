import SwiftUI
import SwiftData

struct TaskCandidatesPanel: View {
    @Environment(\.modelContext) private var modelContext
    var candidates: [AIService.TaskCandidateData]
    var activeTasks: [TaskItem]
    var onApplied: () -> Void
    var sourceDate: String
    
    @State private var checkedIndices: Set<Int> = []
    @State private var isApplying = false
    @State private var hasApplied = false
    @State private var errorMsg: String? = nil
    @State private var expandedIdx: Int? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if candidates.isEmpty {
                Text("メモからタスク候補は見つかりませんでした")
                    .font(Theme.Fonts.mincho(size: 13))
                    .foregroundColor(Theme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(8)
            } else if hasApplied {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle")
                    Text("\(checkedIndices.count) 件のタスクを反映しました")
                }
                .font(Theme.Fonts.mincho(size: 13))
                .foregroundColor(.green)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            } else {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(Theme.goldAccent)
                    Text("タスク候補をご確認ください（\(candidates.count)件）")
                        .font(Theme.Fonts.mincho(size: 14))
                        .foregroundColor(Theme.textPrimary)
                    
                    Spacer()
                    
                    Button("すべて選択") {
                        checkedIndices = Set(0..<candidates.count)
                    }
                    .font(Theme.Fonts.mincho(size: 11))
                    .buttonStyle(.plain)
                    .foregroundColor(Theme.textSecondary)
                    
                    Text("/")
                        .font(Theme.Fonts.mincho(size: 11))
                        .foregroundColor(Theme.textSecondary.opacity(0.5))
                    
                    Button("すべて解除") {
                        checkedIndices.removeAll()
                    }
                    .font(Theme.Fonts.mincho(size: 11))
                    .buttonStyle(.plain)
                    .foregroundColor(Theme.textSecondary)
                }
                
                VStack(spacing: 8) {
                    ForEach(Array(candidates.enumerated()), id: \.offset) { index, c in
                        candidateRow(index: index, c: c)
                    }
                }
                
                if let err = errorMsg {
                    Text(err)
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
                
                HStack(spacing: 12) {
                    Button(action: applySelected) {
                        HStack {
                            if isApplying {
                                ProgressView().scaleEffect(0.5).frame(width: 14, height: 14)
                                Text("適用中...")
                            } else {
                                Image(systemName: "plus")
                                Text("\(checkedIndices.count)件をタスクに反映する")
                            }
                        }
                        .font(Theme.Fonts.mincho(size: 13))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .disabled(isApplying || checkedIndices.isEmpty)
                    .opacity(checkedIndices.isEmpty ? 0.5 : 1.0)
                    
                    Button(action: onApplied) {
                        Text("スキップ")
                            .font(Theme.Fonts.mincho(size: 13))
                            .foregroundColor(Theme.textSecondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .disabled(isApplying)
                }
            }
        }
        .onAppear {
            checkedIndices = Set(0..<candidates.count)
        }
    }
    
    private func candidateRow(index: Int, c: AIService.TaskCandidateData) -> some View {
        let isChecked = checkedIndices.contains(index)
        let isExpanded = expandedIdx == index
        
        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                Button(action: {
                    if isChecked { checkedIndices.remove(index) }
                    else { checkedIndices.insert(index) }
                }) {
                    Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                        .foregroundColor(isChecked ? .blue : Theme.textSecondary)
                }
                .buttonStyle(.plain)
                
                HStack(spacing: 8) {
                    Text(c.type == "new" ? "新規" : "更新")
                        .font(.system(size: 10))
                        .foregroundColor(c.type == "new" ? .blue : .orange)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .overlay(RoundedRectangle(cornerRadius: 3).stroke(c.type == "new" ? Color.blue.opacity(0.3) : Color.orange.opacity(0.3), lineWidth: 1))
                    
                    Text(c.title)
                        .font(Theme.Fonts.mincho(size: 14))
                        .foregroundColor(Theme.textPrimary)
                    
                    if c.priority != "none" {
                        let prioStr = c.priority == "high" ? "高" : (c.priority == "low" ? "低" : "中")
                        let prioColor = c.priority == "high" ? Theme.priorityHigh : (c.priority == "low" ? Theme.textSecondary : Theme.priorityMedium)
                        Text("優先度: \(prioStr)")
                            .font(.system(size: 10))
                            .foregroundColor(prioColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .overlay(RoundedRectangle(cornerRadius: 3).stroke(prioColor.opacity(0.3), lineWidth: 1))
                    }
                }
                
                Spacer()
                
                Button(action: {
                    expandedIdx = isExpanded ? nil : index
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(Theme.textSecondary)
                }
                .buttonStyle(.plain)
            }
            .padding(12)
            .background(isChecked ? Color.white : Theme.cardBackground)
            
            if isExpanded {
                Divider().background(Color.gray.opacity(0.1))
                VStack(alignment: .leading, spacing: 8) {
                    if let desc = c.description {
                        Text(desc)
                            .font(.system(size: 12))
                            .foregroundColor(Theme.textSecondary)
                    }
                    Text("抽出元: 「\(c.reason)」")
                        .font(Theme.Fonts.mincho(size: 11))
                        .foregroundColor(Theme.textSecondary)
                        .padding(6)
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(4)
                }
                .padding(12)
                .background(isChecked ? Color.white : Theme.cardBackground)
            }
        }
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(isChecked ? Theme.textSecondary.opacity(0.3) : Color.gray.opacity(0.1), lineWidth: 1))
        .cornerRadius(8)
    }
    
    private func applySelected() {
        isApplying = true
        errorMsg = nil
        Task {
            // Apply sequentially (needs to be carefully dispatched to main if interacting with ModelContext)
            await MainActor.run {
                for idx in checkedIndices {
                    let c = candidates[idx]
                    if c.type == "new" {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy-MM-dd"
                        var dDue: Date? = nil
                        if let d = c.due_date, let date = formatter.date(from: d) {
                            dDue = date
                        }
                        
                        let newTask = TaskItem(
                            title: c.title,
                            details: c.description ?? "",
                            dueDate: dDue,
                            status: .todo,
                            category: c.category,
                            priority: c.priority,
                            isAIGenerated: true
                        )
                        modelContext.insert(newTask)
                    } else if c.type == "update", let tId = c.target_task_id, let intId = Int(tId), intId < activeTasks.count {
                        let targetTask = activeTasks[intId]
                        if let d = c.description { targetTask.details = d }
                        targetTask.priorityValue = c.priority
                        if let cat = c.category { targetTask.category = cat }
                        
                        if let dStr = c.due_date {
                            let formatter = DateFormatter()
                            formatter.dateFormat = "yyyy-MM-dd"
                            if let date = formatter.date(from: dStr) {
                                targetTask.dueDate = date
                            }
                        }
                    }
                }
                do {
                    try modelContext.save()
                    hasApplied = true
                    onApplied()
                } catch {
                    errorMsg = error.localizedDescription
                }
                isApplying = false
            }
        }
    }
}
