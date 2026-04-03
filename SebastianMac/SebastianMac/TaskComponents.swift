import SwiftUI
import SwiftData

struct AddTaskSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var title: String = ""
    @State private var details: String = ""
    @State private var status: TaskStatus = .todo
    @State private var priority: String = "medium"
    @State private var category: String = ""
    @State private var hasDueDate: Bool = false
    @State private var dueDate: Date = Date()
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("新規タスク")
                    .font(Theme.Fonts.mincho(size: 16))
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .foregroundColor(Theme.textSecondary.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
            .padding(20)
            
            Divider().background(Color.gray.opacity(0.1))
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Task Name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("タスク名")
                            .font(Theme.Fonts.mincho(size: 12))
                            .foregroundColor(Theme.textSecondary)
                        
                        TextField("", text: $title)
                            .font(Theme.Fonts.mincho(size: 14))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Theme.cardBackground)
                            .cornerRadius(6)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.1), lineWidth: 1))
                    }
                    
                    // Status & Due Date
                    HStack(alignment: .top, spacing: 32) {
                        // Status
                        VStack(alignment: .leading, spacing: 8) {
                            Text("ステータス")
                                .font(Theme.Fonts.mincho(size: 12))
                                .foregroundColor(Theme.textSecondary)
                            
                            HStack(spacing: 0) {
                                StatusPill(title: "未着手", isSelected: status == .todo) { status = .todo }
                                StatusPill(title: "進行中", isSelected: status == .inProgress) { status = .inProgress }
                                StatusPill(title: "保留", isSelected: status == .pending) { status = .pending }
                                StatusPill(title: "完了", isSelected: status == .done) { status = .done }
                            }
                        }
                        
                        Spacer()
                        
                        // Due Date
                        VStack(alignment: .trailing, spacing: 8) {
                            HStack {
                                Text("期日を設定")
                                    .font(Theme.Fonts.mincho(size: 12))
                                    .foregroundColor(Theme.textSecondary)
                                Toggle("", isOn: $hasDueDate)
                                    .toggleStyle(SwitchToggleStyle(tint: Color(hex: "6A9E75")))
                                    .labelsHidden()
                            }
                            
                            if hasDueDate {
                                DatePicker("", selection: $dueDate, displayedComponents: [.date])
                                    .labelsHidden()
                                    .environment(\.locale, Locale(identifier: "ja_JP"))
                            }
                        }
                    }
                    
                    // Priority & Category
                    HStack(alignment: .top, spacing: 32) {
                        // Priority
                        VStack(alignment: .leading, spacing: 8) {
                            Text("優先度")
                                .font(Theme.Fonts.mincho(size: 12))
                                .foregroundColor(Theme.textSecondary)
                            
                            HStack(spacing: 0) {
                                StatusPill(title: "高", isSelected: priority == "high") { priority = "high" }
                                StatusPill(title: "中", isSelected: priority == "medium") { priority = "medium" }
                                StatusPill(title: "低", isSelected: priority == "low") { priority = "low" }
                                StatusPill(title: "なし", isSelected: priority == "none") { priority = "none" }
                            }
                        }
                        
                        Spacer()
                        
                        // Category
                        VStack(alignment: .leading, spacing: 8) {
                            Text("カテゴリ")
                                .font(Theme.Fonts.mincho(size: 12))
                                .foregroundColor(Theme.textSecondary)
                            
                            TextField("例: Web会議, 開発...", text: $category)
                                .font(.system(size: 14))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Theme.cardBackground)
                                .cornerRadius(6)
                                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.1), lineWidth: 1))
                        }
                    }
                    
                    // Details
                    VStack(alignment: .leading, spacing: 8) {
                        Text("詳細（任意）")
                            .font(Theme.Fonts.mincho(size: 12))
                            .foregroundColor(Theme.textSecondary)
                        
                        TextEditor(text: $details)
                            .font(Theme.Fonts.mincho(size: 14))
                            .padding(8)
                            .frame(height: 80)
                            .scrollContentBackground(.hidden)
                            .background(Theme.cardBackground)
                            .cornerRadius(6)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.1), lineWidth: 1))
                    }
                }
                .padding(24)
            }
            
            // Footer Buttons
            HStack {
                Spacer()
                
                Button("キャンセル") {
                    dismiss()
                }
                .font(Theme.Fonts.mincho(size: 12))
                .foregroundColor(Theme.textSecondary)
                .buttonStyle(.plain)
                .padding(.trailing, 16)
                
                Button("追加") {
                    let task = TaskItem(
                        title: title,
                        details: details,
                        dueDate: hasDueDate ? dueDate : nil,
                        status: status,
                        category: category.isEmpty ? nil : category,
                        priority: priority,
                        isAIGenerated: false
                    )
                    modelContext.insert(task)
                    try? modelContext.save()
                    dismiss()
                }
                .font(Theme.Fonts.mincho(size: 12))
                .foregroundColor(Theme.buttonTextOnSidebar)
                .padding(.horizontal, 24)
                .padding(.vertical, 8)
                .background(Theme.sidebarBackground)
                .cornerRadius(6)
                .buttonStyle(.plain)
                .disabled(title.isEmpty)
                .opacity(title.isEmpty ? 0.5 : 1.0)
            }
            .padding(20)
            .background(Color.white.shadow(color: .black.opacity(0.05), radius: 5, y: -2))
        }
        .frame(width: 480, height: 600)
        .background(Theme.mainBackground)
    }
}

struct TaskRowView: View {
    @Bindable var task: TaskItem
    var isLast: Bool
    var onEdit: () -> Void
    var onTapToggle: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 16) {
                // Checkbox
                Button(action: onTapToggle) {
                    if task.status == .done {
                        Image(systemName: "checkmark.circle")
                            .foregroundColor(Theme.statusDone)
                            .font(.system(size: 20))
                    } else if task.status == .inProgress {
                        Image(systemName: "sun.min") // 進行中アイコン
                            .foregroundColor(Theme.priorityMedium) // 青色
                            .font(.system(size: 20))
                    } else {
                        // todo or pending
                        Image(systemName: "circle")
                            .foregroundColor(Theme.textSecondary.opacity(0.3))
                            .font(.system(size: 20))
                    }
                }
                .buttonStyle(.plain)
                
                // Titles
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(Theme.Fonts.mincho(size: 14))
                        .foregroundColor(task.status == .done ? Theme.textSecondary : Theme.textPrimary)
                        .strikethrough(task.status == .done)
                    
                    HStack(spacing: 8) {
                        if let cat = task.category, !cat.isEmpty {
                            Text(cat)
                                .font(Theme.Fonts.mincho(size: 11))
                                .foregroundColor(Theme.textSecondary)
                        }
                        
                        if let date = task.dueDate {
                            Text("期日: \(formatDate(date))")
                                .font(.system(size: 11))
                                .foregroundColor(Theme.textSecondary)
                        }
                        
                        if !task.details.isEmpty {
                            Text(task.details)
                                .font(Theme.Fonts.mincho(size: 11))
                                .foregroundColor(Theme.textSecondary.opacity(0.6))
                                .lineLimit(1)
                        }
                    }
                }
                
                Spacer()
                
                // Right side: priority and pin
                HStack(spacing: 12) {
                    if task.priorityValue == "high" {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 6))
                            .foregroundColor(Theme.priorityHigh)
                    }
                     
                    let priorityStr = task.priorityValue == "high" ? "高" : (task.priorityValue == "low" ? "低" : (task.priorityValue == "medium" ? "中" : "なし"))
                    let prioColor = task.priorityValue == "high" ? Theme.priorityHigh : (task.priorityValue == "low" ? Theme.textSecondary : (task.priorityValue == "medium" ? Theme.priorityMedium : Theme.textSecondary.opacity(0.5)))
                    
                    if priorityStr != "なし" {
                        Text(priorityStr)
                            .font(Theme.Fonts.mincho(size: 12))
                            .foregroundColor(prioColor)
                    }
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 24)
            .contentShape(Rectangle())
            .onTapGesture {
                onEdit()
            }
            
            if !isLast {
                Divider()
                    .background(Color.gray.opacity(0.1))
                    .padding(.horizontal, 24)
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}

struct EditTaskSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var task: TaskItem
    
    @State private var tempCategory: String = ""
    @State private var hasDueDate: Bool = false
    @State private var tempDueDate: Date = Date()
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("タスクの編集")
                    .font(Theme.Fonts.mincho(size: 16))
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .foregroundColor(Theme.textSecondary.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
            .padding(20)
            
            Divider().background(Color.gray.opacity(0.1))
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Task Name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("タスク名")
                            .font(Theme.Fonts.mincho(size: 12))
                            .foregroundColor(Theme.textSecondary)
                        
                        TextField("", text: $task.title)
                            .font(Theme.Fonts.mincho(size: 14))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Theme.cardBackground)
                            .cornerRadius(6)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.1), lineWidth: 1))
                    }
                    
                    // Status & Due Date
                    HStack(alignment: .top, spacing: 32) {
                        // Status
                        VStack(alignment: .leading, spacing: 8) {
                            Text("ステータス")
                                .font(Theme.Fonts.mincho(size: 12))
                                .foregroundColor(Theme.textSecondary)
                            
                            HStack(spacing: 0) {
                                StatusPill(title: "未着手", isSelected: task.status == .todo) { task.status = .todo }
                                StatusPill(title: "進行中", isSelected: task.status == .inProgress) { task.status = .inProgress }
                                StatusPill(title: "保留", isSelected: task.status == .pending) { task.status = .pending }
                                StatusPill(title: "完了", isSelected: task.status == .done) { task.status = .done }
                            }
                        }
                        
                        Spacer()
                        
                        // Due Date
                        VStack(alignment: .trailing, spacing: 8) {
                            HStack {
                                Text("期日を設定")
                                    .font(Theme.Fonts.mincho(size: 12))
                                    .foregroundColor(Theme.textSecondary)
                                Toggle("", isOn: $hasDueDate)
                                    .toggleStyle(SwitchToggleStyle(tint: Color(hex: "6A9E75")))
                                    .labelsHidden()
                                    .onChange(of: hasDueDate) { _, newValue in
                                        if newValue { task.dueDate = tempDueDate } else { task.dueDate = nil }
                                    }
                            }
                            
                            if hasDueDate {
                                DatePicker("", selection: $tempDueDate, displayedComponents: [.date])
                                    .labelsHidden()
                                    .environment(\.locale, Locale(identifier: "ja_JP"))
                                    .onChange(of: tempDueDate) { _, newValue in task.dueDate = newValue }
                            }
                        }
                    }
                    
                    // Priority & Category
                    HStack(alignment: .top, spacing: 32) {
                        // Priority
                        VStack(alignment: .leading, spacing: 8) {
                            Text("優先度")
                                .font(Theme.Fonts.mincho(size: 12))
                                .foregroundColor(Theme.textSecondary)
                            
                            HStack(spacing: 0) {
                                StatusPill(title: "高", isSelected: task.priorityValue == "high") { task.priorityValue = "high" }
                                StatusPill(title: "中", isSelected: task.priorityValue == "medium") { task.priorityValue = "medium" }
                                StatusPill(title: "低", isSelected: task.priorityValue == "low") { task.priorityValue = "low" }
                                StatusPill(title: "なし", isSelected: task.priorityValue == "none") { task.priorityValue = "none" }
                            }
                        }
                        
                        Spacer()
                        
                        // Category
                        VStack(alignment: .leading, spacing: 8) {
                            Text("カテゴリ")
                                .font(Theme.Fonts.mincho(size: 12))
                                .foregroundColor(Theme.textSecondary)
                            
                            TextField("例: Web会議, 開発...", text: $tempCategory)
                                .font(.system(size: 14))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Theme.cardBackground)
                                .cornerRadius(6)
                                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.1), lineWidth: 1))
                                .onChange(of: tempCategory) { _, newValue in
                                    task.category = newValue.isEmpty ? nil : newValue
                                }
                        }
                    }
                    
                    // Details
                    VStack(alignment: .leading, spacing: 8) {
                        Text("詳細（任意）")
                            .font(Theme.Fonts.mincho(size: 12))
                            .foregroundColor(Theme.textSecondary)
                        
                        TextEditor(text: $task.details)
                            .font(Theme.Fonts.mincho(size: 14))
                            .padding(8)
                            .frame(height: 80)
                            .scrollContentBackground(.hidden)
                            .background(Theme.cardBackground)
                            .cornerRadius(6)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.1), lineWidth: 1))
                    }
                }
                .padding(24)
            }
            
            // Footer Buttons
            HStack {
                Button("削除") {
                    modelContext.delete(task)
                    try? modelContext.save()
                    dismiss()
                }
                .font(Theme.Fonts.mincho(size: 12))
                .foregroundColor(.red)
                .buttonStyle(.plain)
                
                Spacer()
                
                Button("キャンセル") {
                    dismiss()
                }
                .font(Theme.Fonts.mincho(size: 12))
                .foregroundColor(Theme.textSecondary)
                .buttonStyle(.plain)
                .padding(.trailing, 16)
                
                Button("保存") {
                    try? modelContext.save()
                    dismiss()
                }
                .font(Theme.Fonts.mincho(size: 12))
                .foregroundColor(Theme.buttonTextOnSidebar)
                .padding(.horizontal, 24)
                .padding(.vertical, 8)
                .background(Theme.sidebarBackground)
                .cornerRadius(6)
                .buttonStyle(.plain)
                .disabled(task.title.isEmpty)
                .opacity(task.title.isEmpty ? 0.5 : 1.0)
            }
            .padding(20)
            .background(Color.white.shadow(color: .black.opacity(0.05), radius: 5, y: -2))
        }
        .frame(width: 480, height: 600)
        .background(Theme.mainBackground)
        .onAppear {
            tempCategory = task.category ?? ""
            if let d = task.dueDate {
                hasDueDate = true
                tempDueDate = d
            } else {
                hasDueDate = false
            }
        }
    }
}

// MARK: - Components UI
struct StatusPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.Fonts.mincho(size: 10))
                .foregroundColor(isSelected ? .white : Theme.textSecondary)
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(isSelected ? Color(hex: "007AFF") : Theme.cardBackground)
                .cornerRadius(4)
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(isSelected ? Color.clear : Color.gray.opacity(0.1), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .padding(.trailing, 4)
    }
}
