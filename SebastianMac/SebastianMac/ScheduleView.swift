import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ScheduleView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskItem.dueDate, order: .forward) private var tasks: [TaskItem]
    
    @State private var mode: ScheduleMode = .week
    @State private var currentDate: Date = Date()
    
    var body: some View {
        VStack(spacing: 0) {
            // Header: title, controls, mode switcher
            HStack {
                Text("スケジュール (Schedule)")
                    .font(Theme.Fonts.mincho(size: 28))
                    .foregroundColor(Theme.textPrimary)
                
                Spacer()
                
                // Navigation controls
                HStack(spacing: 24) {
                    HStack(spacing: 16) {
                        Button(action: { moveDate(by: -1) }) {
                            Image(systemName: "chevron.left")
                                .padding(8)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        
                        Text(headerDateRangeString)
                            .font(Theme.Fonts.mincho(size: 16))
                            .frame(width: 150, alignment: .center)
                        
                        Button(action: { moveDate(by: 1) }) {
                            Image(systemName: "chevron.right")
                                .padding(8)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        
                        Button("今日") {
                            currentDate = Date()
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.goldAccent))
                    }
                    
                    // Mode Switcher
                    HStack(spacing: 0) {
                        ForEach(ScheduleMode.allCases, id: \.self) { m in
                            Button(action: { mode = m }) {
                                Text(m.rawValue)
                                    .font(Theme.Fonts.mincho(size: 12))
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 16)
                                    .background(mode == m ? Theme.goldAccent : Color.clear)
                                    .foregroundColor(mode == m ? .white : Theme.textPrimary)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .background(Theme.cardBackground)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, 32)
            .padding(.bottom, 24)
            
            // Calendar Body
            ZStack {
                switch mode {
                case .day:
                    DayScheduleView(currentDate: currentDate, tasks: tasksFor(date: currentDate))
                case .week:
                    WeekScheduleView(currentDate: currentDate, scheduleView: self)
                case .month:
                    MonthScheduleView(currentDate: currentDate, scheduleView: self)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
    }
    
    // MARK: - Helpers
    
    func tasksFor(date: Date) -> [TaskItem] {
        return tasks.filter { task in
            guard let d = task.dueDate else { return false }
            return Calendar.current.isDate(d, inSameDayAs: date)
        }.sorted { t1, t2 in
            if t1.status == .done && t2.status != .done { return false }
            if t1.status != .done && t2.status == .done { return true }
            return t1.title < t2.title
        }
    }
    
    private var headerDateRangeString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        
        switch mode {
        case .day:
            formatter.dateFormat = "yyyy年M月d日"
            return formatter.string(from: currentDate)
        case .week:
            let start = weekDates.first!
            let end = weekDates.last!
            formatter.dateFormat = "M/d"
            return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
        case .month:
            formatter.dateFormat = "yyyy年M月"
            return formatter.string(from: currentDate)
        }
    }
    
    var weekDates: [Date] {
        let cal = Calendar.current
        let startOfDay = cal.startOfDay(for: currentDate)
        let weekday = cal.component(.weekday, from: startOfDay)
        let diff = (2 - weekday - 7) % 7 + (weekday == 1 ? 0 : 7) // 月曜始まり
        let startOfWeek = cal.date(byAdding: .day, value: diff > 0 ? diff - 7 : diff, to: startOfDay)!
        return (0..<7).map { cal.date(byAdding: .day, value: $0, to: startOfWeek)! }
    }
    
    private func moveDate(by offset: Int) {
        let cal = Calendar.current
        switch mode {
        case .day:
            currentDate = cal.date(byAdding: .day, value: offset, to: currentDate)!
        case .week:
            currentDate = cal.date(byAdding: .day, value: offset * 7, to: currentDate)!
        case .month:
            currentDate = cal.date(byAdding: .month, value: offset, to: currentDate)!
        }
    }
}

// MARK: - Day View
struct DayScheduleView: View {
    let currentDate: Date
    let tasks: [TaskItem]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if tasks.isEmpty {
                    Text("予定はありません")
                        .foregroundColor(Theme.textSecondary)
                } else {
                    ForEach(tasks) { task in
                        ScheduleTaskCard(task: task)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Theme.cardBackground)
            .cornerRadius(12)
        }
    }
}

// MARK: - Week View
struct WeekScheduleView: View {
    @Environment(\.modelContext) private var modelContext
    let currentDate: Date
    let scheduleView: ScheduleView
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(scheduleView.weekDates, id: \.self) { date in
                VStack(spacing: 8) {
                    // Header
                    VStack(spacing: 4) {
                        Text(formatWeekday(date))
                            .font(Theme.Fonts.mincho(size: 12))
                            .foregroundColor(Theme.textSecondary)
                        Text(formatDay(date))
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Calendar.current.isDateInToday(date) ? Theme.goldAccent : Theme.textPrimary)
                    }
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(Calendar.current.isDateInToday(date) ? Theme.goldAccent.opacity(0.1) : Color.clear)
                    .cornerRadius(8)
                    
                    // Task Drop Zone
                    GeometryReader { geo in
                        ScrollView {
                            VStack(spacing: 4) {
                                ForEach(scheduleView.tasksFor(date: date)) { task in
                                    ScheduleTaskCard(task: task)
                                        .onDrag {
                                            let idString = task.createdAt.timeIntervalSince1970.description
                                            return NSItemProvider(object: idString as NSString)
                                        }
                                }
                            }
                            .padding(4)
                            .frame(minHeight: geo.size.height, alignment: .top)
                        }
                    }
                    .background(Theme.cardBackground)
                    .cornerRadius(8)
                    .onDrop(of: [.plainText], isTargeted: nil) { providers, location in
                        providers.first?.loadObject(ofClass: NSString.self) { item, error in
                            if let uriStr = item as? String {
                                Task { @MainActor in
                                    updateTaskDueDate(idStr: uriStr, newDate: date)
                                }
                            }
                        }
                        return true
                    }
                }
            }
        }
    }
    
    @MainActor
    private func updateTaskDueDate(idStr: String, newDate: Date) {
        do {
            let allTasks = try modelContext.fetch(FetchDescriptor<TaskItem>())
            if let dragged = allTasks.first(where: { $0.createdAt.timeIntervalSince1970.description == idStr }) {
                dragged.dueDate = newDate
                try? modelContext.save()
            }
        } catch {}
    }
    
    private func formatWeekday(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "E"
        return f.string(from: date)
    }
    
    private func formatDay(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "d"
        return f.string(from: date)
    }
}

// MARK: - Month View
struct MonthScheduleView: View {
    @Environment(\.modelContext) private var modelContext
    let currentDate: Date
    let scheduleView: ScheduleView
    
    @State private var popoverDate: Date? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Days
            HStack(spacing: 0) {
                ForEach(["月", "火", "水", "木", "金", "土", "日"], id: \.self) { w in
                    Text(w)
                        .font(Theme.Fonts.mincho(size: 12))
                        .foregroundColor(Theme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
            }
            .background(Theme.cardBackground)
            
            // Grid
            let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
            GeometryReader { geo in
                LazyVGrid(columns: columns, spacing: 0) {
                    ForEach(monthDates, id: \.self) { date in
                        let tasks = scheduleView.tasksFor(date: date)
                        let isToday = Calendar.current.isDateInToday(date)
                        let isCurrentMonth = Calendar.current.isDate(date, equalTo: currentDate, toGranularity: .month)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(formatDay(date))
                                .font(.system(size: 12, weight: isToday ? .bold : .regular))
                                .foregroundColor(isToday ? Theme.goldAccent : (isCurrentMonth ? Theme.textPrimary : Theme.textSecondary.opacity(0.5)))
                                .padding(4)
                            
                            if !tasks.isEmpty {
                                HStack(spacing: 2) {
                                    Circle().fill(Theme.goldAccent).frame(width: 4, height: 4)
                                    Text("\(tasks.count) 件")
                                        .font(.system(size: 10))
                                        .foregroundColor(Theme.textSecondary)
                                }
                                .padding(.horizontal, 4)
                            }
                            Spacer()
                        }
                        .frame(height: geo.size.height / 6)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .background(Theme.cardBackground)
                        .border(Color.gray.opacity(0.1), width: 0.5)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if !tasks.isEmpty {
                                popoverDate = date
                            }
                        }
                        .popover(item: Binding<DateWrapper?>(
                            get: { popoverDate.map { DateWrapper(date: $0) } },
                            set: { if let newDate = $0 { popoverDate = newDate.date } else { popoverDate = nil } }
                        )) { dateObj in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(formatDetailedDate(dateObj.date))
                                    .font(Theme.Fonts.mincho(size: 14))
                                    .foregroundColor(Theme.textPrimary)
                                    .padding(.bottom, 4)
                                
                                ForEach(scheduleView.tasksFor(date: dateObj.date)) { task in
                                    HStack {
                                        Image(systemName: task.status == .done ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(task.status == .done ? Theme.statusDone : Theme.goldAccent)
                                        Text(task.title)
                                            .font(Theme.Fonts.mincho(size: 12))
                                            .foregroundColor(task.status == .done ? Theme.textSecondary : Theme.textPrimary)
                                            .strikethrough(task.status == .done)
                                    }
                                }
                            }
                            .padding()
                            .frame(width: 200)
                        }
                    }
                }
            }
        }
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var monthDates: [Date] {
        let calendar = Calendar.current
        var dates: [Date] = []
        
        let comp = calendar.dateComponents([.year, .month], from: currentDate)
        let monthStart = calendar.date(from: comp)!
        
        let monthRange = calendar.range(of: .day, in: .month, for: monthStart)!
        let firstWeekday = calendar.component(.weekday, from: monthStart)
        let offset = (firstWeekday + 5) % 7 // 月曜始まりのアライメント
        
        // 前月分
        if offset > 0 {
            for i in (1...offset).reversed() {
                if let pd = calendar.date(byAdding: .day, value: -i, to: monthStart) { dates.append(pd) }
            }
        }
        
        // 当月分
        for i in 0..<monthRange.count {
            if let cd = calendar.date(byAdding: .day, value: i, to: monthStart) { dates.append(cd) }
        }
        
        // 翌月分（42マス埋め）
        let remaining = 42 - dates.count
        if remaining > 0, let lastDate = dates.last {
            for i in 1...remaining {
                if let nd = calendar.date(byAdding: .day, value: i, to: lastDate) { dates.append(nd) }
            }
        }
        return dates
    }
    
    private func formatDay(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "d"
        return f.string(from: date)
    }
    
    private func formatDetailedDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "M/d(E)"
        f.locale = Locale(identifier: "ja_JP")
        return f.string(from: date)
    }
}

struct DateWrapper: Identifiable {
    var id: Date { date }
    var date: Date
}

// MARK: - ScheduleTaskCard
struct ScheduleTaskCard: View {
    @Bindable var task: TaskItem
    @State private var isShowingPopover = false
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(task.status == .done ? Theme.statusDone : Theme.priorityMedium)
                .frame(width: 8, height: 8)
            
            Text(task.title)
                .font(Theme.Fonts.mincho(size: 11))
                .foregroundColor(task.status == .done ? Theme.textSecondary : Theme.textPrimary)
                .strikethrough(task.status == .done)
                .lineLimit(1)
            
            Spacer(minLength: 0)
        }
        .padding(8)
        .background(task.status == .done ? Theme.mainBackground : .white)
        .cornerRadius(4)
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.gray.opacity(0.2)))
        .onTapGesture {
            if !task.details.isEmpty {
                isShowingPopover = true
            }
        }
        .popover(isPresented: $isShowingPopover, arrowEdge: .trailing) {
            VStack(alignment: .leading, spacing: 8) {
                Text(task.title)
                    .font(Theme.Fonts.mincho(size: 14).bold())
                Text(task.details)
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textSecondary)
            }
            .padding()
            .frame(width: 200)
        }
    }
}
