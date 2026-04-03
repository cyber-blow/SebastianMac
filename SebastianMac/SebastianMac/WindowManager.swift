import AppKit

struct WindowManager {
    static func setupWindow() {
        if let window = NSApplication.shared.windows.first {
            window.titlebarAppearsTransparent = true
            window.isMovableByWindowBackground = true // 背景ドラッグでウィンドウ移動可能に
            window.titleVisibility = .hidden
        }
    }
}
