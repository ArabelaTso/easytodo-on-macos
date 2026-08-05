import AppKit

@MainActor
final class WindowManager: ObservableObject {
    static let shared = WindowManager()

    private var mainWindow: NSWindow?

    private init() {}

    func configureMainWindow(_ window: NSWindow) {
        mainWindow = window
        window.identifier = NSUserInterfaceItemIdentifier("easy-todo-main-window")
        window.title = "EasyTODO"
        window.minSize = NSSize(width: 280, height: 320)
        window.setContentSize(NSSize(width: 340, height: 480))
        window.isOpaque = false
        window.backgroundColor = .clear
        window.titlebarAppearsTransparent = false
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.styleMask.insert(.fullSizeContentView)
        window.styleMask.insert(.resizable)
        hideNativeWindowControls(in: window)
        window.styleMask.remove(.titled)
        window.collectionBehavior.insert(.canJoinAllSpaces)
        window.collectionBehavior.insert(.fullScreenAuxiliary)

        DispatchQueue.main.async { [weak window] in
            guard let window else { return }
            self.hideNativeWindowControls(in: window)
            window.styleMask.remove(.titled)
        }

        applyWindowSettings()
    }

    private func hideNativeWindowControls(in window: NSWindow) {
        window.standardWindowButton(.closeButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        window.standardWindowButton(.closeButton)?.superview?.isHidden = true
    }

    func applyWindowSettings() {
        guard let window = mainWindow else { return }

        let defaults = UserDefaults.standard
        let alwaysOnTop = defaults.bool(forKey: EasyTODOSettings.alwaysOnTop)
        let transparency = defaults.double(forKey: EasyTODOSettings.transparency)

        window.level = alwaysOnTop ? .floating : .normal
        window.alphaValue = min(max(transparency, 0.80), 1.0)
    }

    func applyActivationPolicy() {
        let defaults = UserDefaults.standard
        let hideDockIcon = defaults.bool(forKey: EasyTODOSettings.hiddenDockIcon)
        let showMenuBar = defaults.bool(forKey: EasyTODOSettings.showMenuBar)

        NSApp.setActivationPolicy(hideDockIcon && showMenuBar ? .accessory : .regular)
    }

    func showMainWindow() {
        if let window = mainWindow {
            window.makeKeyAndOrderFront(nil)
        }

        NSApp.activate(ignoringOtherApps: true)
    }

    func closeMainWindow() {
        mainWindow?.close()
    }

    func minimizeMainWindow() {
        mainWindow?.miniaturize(nil)
    }

    func zoomMainWindow() {
        mainWindow?.performZoom(nil)
    }
}
