import Foundation
import SwiftData
import SwiftUI

@Model
final class TaskItem {
    var title: String
    var details: String
    var dueDate: Date?
    var statusValue: String
    var category: String?
    var priorityValue: String
    var isAIGenerated: Bool
    var createdAt: Date
    
    var status: TaskStatus {
        get { TaskStatus(rawValue: statusValue) ?? .todo }
        set { statusValue = newValue.rawValue }
    }
    
    init(title: String, details: String = "", dueDate: Date? = nil, status: TaskStatus = .todo, category: String? = nil, priority: String = "none", isAIGenerated: Bool = false) {
        self.title = title
        self.details = details
        self.dueDate = dueDate
        self.statusValue = status.rawValue
        self.category = category
        self.priorityValue = priority
        self.isAIGenerated = isAIGenerated
        self.createdAt = Date()
    }
}

@Model
final class Memo {
    var content: String
    var isProcessed: Bool
    var createdAt: Date
    
    init(content: String, isProcessed: Bool = false) {
        self.content = content
        self.isProcessed = isProcessed
        self.createdAt = Date()
    }
}

@Model
final class DailyNippo {
    var content: String
    var createdAt: Date
    var isExported: Bool
    
    init(content: String, isExported: Bool = false) {
        self.content = content
        self.isExported = isExported
        self.createdAt = Date()
    }
}

@Model
final class WeeklyShuho {
    var content: String
    var createdAt: Date
    var isExported: Bool
    
    init(content: String, isExported: Bool = false) {
        self.content = content
        self.isExported = isExported
        self.createdAt = Date()
    }
}

enum TaskStatus: String, CaseIterable, Codable {
    case todo = "todo"
    case inProgress = "inProgress"
    case pending = "pending"
    case done = "done"
}

enum SidebarItem: String, CaseIterable {
    case dashboard = "ホーム"
    case memo = "今日のメモ"
    case task = "タスク"
    case schedule = "スケジュール"
    case nippo = "日報"
    case shuho = "週報"
    case settings = "設定"
    
    var iconName: String {
        switch self {
        case .dashboard: return "square.grid.2x2"
        case .memo: return "pencil.line"
        case .task: return "checklist"
        case .schedule: return "calendar"
        case .nippo: return "doc.text"
        case .shuho: return "doc.text.fill"
        case .settings: return "gearshape"
        }
    }
}

enum ScheduleMode: String, CaseIterable {
    case day = "日"
    case week = "週"
    case month = "月"
}

struct Theme {
    static var themeMode: String { UserDefaults.standard.string(forKey: "appTheme") ?? "sepia" }
    
    static var sidebarBackground: Color {
        switch themeMode {
        case "light": return Color(hex: "E5E5EA") // 薄いグレー
        case "dark": return Color(hex: "1C1C1E") // ほぼ黒
        default: return Color(hex: "1C2A4A") // 紺（セピア時）
        }
    }
    
    static var buttonTextOnSidebar: Color {
        switch themeMode {
        case "light": return Color(hex: "1C1C1E")
        case "dark": return Color.white
        default: return Color(hex: "F6F0E4")
        }
    }
    
    static var sidebarSelected: Color {
        switch themeMode {
        case "light": return Color.black.opacity(0.1)
        case "dark": return Color.white.opacity(0.1)
        default: return Color(white: 1.0, opacity: 0.1)
        }
    }
    
    static var mainBackground: Color {
        switch themeMode {
        case "light": return Color(hex: "F2F2F7") // 最も明るいグレー
        case "dark": return Color(hex: "000000") // 真っ黒
        default: return Color(hex: "F6F0E4") // ベージュ（セピア）
        }
    }
    
    static var cardBackground: Color {
        switch themeMode {
        case "light": return Color.white
        case "dark": return Color(hex: "1C1C1E")
        default: return Color.white
        }
    }
    
    static var textPrimary: Color {
        switch themeMode {
        case "light": return Color(hex: "1C1C1E")
        case "dark": return Color(hex: "E5E5EA")
        default: return Color(hex: "333333")
        }
    }
    
    static var textSecondary: Color {
        switch themeMode {
        case "light": return Color(hex: "8E8E93")
        case "dark": return Color(hex: "98989D")
        default: return Color(hex: "888888")
        }
    }
    
    static let goldAccent = Color(hex: "bbaa8d") // ゴールドのアクセント
    
    // タスクの優先度・状態用カラー
    static let priorityHigh = Color(hex: "D97373")  // 赤系
    static let priorityMedium = Color(hex: "638DCC") // 青系
    static let priorityLow = Color(hex: "A39A86")   // 薄い茶色・グレー系
    static let statusDone = Color(hex: "6EB18C")    // 緑系
    
    struct Fonts {
        static func mincho(size: CGFloat) -> Font {
            return Font.custom("Hiragino Mincho ProN", size: size)
        }
        static func cinzel(size: CGFloat) -> Font {
            return Font.custom("Cinzel", size: size)
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
