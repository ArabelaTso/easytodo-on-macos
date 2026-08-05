import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        EasyTODOSettings.registerDefaults()
        AppLogo.applyApplicationIcon()
        GlobalShortcutManager.shared.registerQuickAddShortcut()
        WindowManager.shared.applyActivationPolicy()
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationWillTerminate(_ notification: Notification) {
        GlobalShortcutManager.shared.unregisterQuickAddShortcut()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
