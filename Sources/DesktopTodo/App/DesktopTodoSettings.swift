import Foundation

enum DesktopTodoSettings {
    static let launchAtLogin = "launchAtLogin"
    static let alwaysOnTop = "alwaysOnTop"
    static let showMenuBar = "showMenuBar"
    static let hiddenDockIcon = "hiddenDockIcon"
    static let transparency = "transparency"
    static let theme = "theme"

    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            launchAtLogin: false,
            alwaysOnTop: true,
            showMenuBar: true,
            hiddenDockIcon: false,
            transparency: 0.90,
            theme: ThemeOption.system.rawValue
        ])
    }
}

enum ThemeOption: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system:
            "System"
        case .light:
            "Light"
        case .dark:
            "Dark"
        }
    }
}
