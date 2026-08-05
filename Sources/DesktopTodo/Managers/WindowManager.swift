import AppKit

@MainActor
final class WindowManager: ObservableObject {
    static let shared = WindowManager()

    private var mainWindow: NSWindow?

    private init() {}

    func configureMainWindow(_ window: NSWindow) {
        mainWindow = window
        window.identifier = NSUserInterfaceItemIdentifier("desktop-todo-main-window")
        window.title = "Desktop Todo"
        window.minSize = NSSize(width: 280, height: 320)
        window.setContentSize(NSSize(width: 340, height: 480))
        window.isOpaque = false
        window.backgroundColor = .clear
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.collectionBehavior.insert(.canJoinAllSpaces)
        window.collectionBehavior.insert(.fullScreenAuxiliary)

        applyWindowSettings()
    }

    func applyWindowSettings() {
        guard let window = mainWindow else { return }

        let defaults = UserDefaults.standard
        let alwaysOnTop = defaults.bool(forKey: DesktopTodoSettings.alwaysOnTop)
        let transparency = defaults.double(forKey: DesktopTodoSettings.transparency)

        window.level = alwaysOnTop ? .floating : .normal
        window.alphaValue = min(max(transparency, 0.80), 1.0)
    }

    func applyActivationPolicy() {
        let defaults = UserDefaults.standard
        let hideDockIcon = defaults.bool(forKey: DesktopTodoSettings.hiddenDockIcon)
        let showMenuBar = defaults.bool(forKey: DesktopTodoSettings.showMenuBar)

        NSApp.setActivationPolicy(hideDockIcon && showMenuBar ? .accessory : .regular)
    }

    func showMainWindow() {
        if let window = mainWindow {
            window.makeKeyAndOrderFront(nil)
        }

        NSApp.activate(ignoringOtherApps: true)
    }
}
