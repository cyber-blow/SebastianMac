import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("appTheme") private var appTheme: String = "sepia"
    @State private var selectedItem: SidebarItem = .dashboard
    @State private var showBriefing: Bool = false
    @AppStorage("lastBriefingDate") private var lastBriefingDate: String = ""
    
    var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            SidebarView(selectedItem: $selectedItem, appTheme: $appTheme)
                .frame(width: 240)
            
            // Main Content Area
            ZStack {
                Theme.mainBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    CustomTitleBar()
                    
                    switch selectedItem {
                    case .dashboard:
                        DashboardView()
                    case .memo:
                        MemoView()
                    case .task:
                        TaskListView()
                    case .schedule:
                        ScheduleView()
                    case .nippo:
                        NippoView()
                    case .shuho:
                        ShuhoView()
                    case .settings:
                        SettingsView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .id(appTheme)
        .preferredColorScheme(appTheme == "dark" ? .dark : .light)
        .onAppear {
            WindowManager.setupWindow()
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let todayStr = formatter.string(from: Date())
            if lastBriefingDate != todayStr {
                showBriefing = true
            }
        }
        .sheet(isPresented: $showBriefing) {
            MorningBriefingView()
        }
    }
}

struct SidebarView: View {
    @Binding var selectedItem: SidebarItem
    @Binding var appTheme: String
    
    var body: some View {
        ZStack {
            Theme.sidebarBackground.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 0) {
                // Header (Logo/Title) - custom draggable area
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .stroke(Theme.goldAccent.opacity(0.5), lineWidth: 1)
                            .frame(width: 28, height: 28)
                        Text("S")
                            .font(Theme.Fonts.cinzel(size: 16))
                            .foregroundColor(Theme.goldAccent)
                    }
                    Text("SEBASTIAN")
                        .font(Theme.Fonts.cinzel(size: 16))
                        .foregroundColor(Theme.textPrimary)
                        .kerning(1.5)
                }
                .padding(.horizontal, 24)
                .padding(.top, 40)
                .padding(.bottom, 32)
                
                // Menus
                ScrollView {
                    VStack(spacing: 24) {
                        MenuSection(title: "", items: [.dashboard, .memo, .task, .schedule], selectedItem: $selectedItem)
                        MenuSection(title: "レポート", items: [.nippo, .shuho], selectedItem: $selectedItem)
                    }
                    .padding(.horizontal, 16)
                }
                
                Spacer()
                
                // Settings & Footer
                VStack(spacing: 16) {
                    SidebarMenuRow(item: .settings, isSelected: selectedItem == .settings) {
                        selectedItem = .settings
                    }
                    .padding(.horizontal, 16)
                    
                    // Butler Image Placeholder
                    Image(systemName: "person.bust.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundColor(Theme.textSecondary.opacity(0.3))
                        .padding(.bottom, 24)
                    
                    // Theme Switcher
                    HStack(spacing: 8) {
                        ThemeButton(icon: "sun.max", title: "ライト", isSelected: appTheme == "light") { appTheme = "light" }
                        ThemeButton(icon: "moon", title: "ダーク", isSelected: appTheme == "dark") { appTheme = "dark" }
                        ThemeButton(icon: "cup.and.saucer", title: "セピア", isSelected: appTheme == "sepia") { appTheme = "sepia" }
                    }
                    .padding(.bottom, 16)
                    

                }
            }
        }
    }
}

struct MenuSection: View {
    var title: String
    var items: [SidebarItem]
    @Binding var selectedItem: SidebarItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !title.isEmpty {
                Text(title)
                    .font(Theme.Fonts.mincho(size: 10))
                    .foregroundColor(Theme.textSecondary)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 4)
            }
            
            ForEach(items, id: \.self) { item in
                SidebarMenuRow(item: item, isSelected: selectedItem == item) {
                    selectedItem = item
                }
            }
        }
    }
}

struct SidebarMenuRow: View {
    var item: SidebarItem
    var isSelected: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: item.iconName)
                    .font(.system(size: 14))
                    .frame(width: 20)
                    .foregroundColor(isSelected ? Theme.goldAccent : Theme.textSecondary)
                
                Text(item.rawValue)
                    .font(Theme.Fonts.mincho(size: 14))
                    .foregroundColor(isSelected ? Theme.goldAccent : Theme.textSecondary)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isSelected ? Theme.sidebarSelected : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

struct ThemeButton: View {
    var icon: String
    var title: String
    var isSelected: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                Text(title)
                    .font(Theme.Fonts.mincho(size: 10))
            }
            .foregroundColor(isSelected ? Theme.goldAccent : Theme.textSecondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isSelected ? Theme.sidebarSelected : Color.clear)
            .cornerRadius(4)
        }
        .buttonStyle(.plain)
    }
}

// カスタムタイトルバー（ドラッグ領域）
struct CustomTitleBar: View {
    var body: some View {
        Rectangle()
            .fill(Color.clear)
            .frame(height: 28)
            .overlay(
                // Mac標準のシグナル（赤黄緑ボタン）のレイアウト確保用の領域として機能。
                // 実際のボタンはWindowが自動描画します
                Color.clear
            )
    }
}
