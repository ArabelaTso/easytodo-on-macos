import Foundation

enum EasyTODOSettings {
    static let launchAtLogin = "launchAtLogin"
    static let alwaysOnTop = "alwaysOnTop"
    static let showMenuBar = "showMenuBar"
    static let hiddenDockIcon = "hiddenDockIcon"
    static let transparency = "transparency"
    static let widgetTransparency = "widgetTransparency"
    static let theme = "theme"

    static func registerDefaults() {
        let defaults = UserDefaults.standard
        defaults.register(defaults: [
            launchAtLogin: false,
            alwaysOnTop: true,
            showMenuBar: true,
            hiddenDockIcon: false,
            transparency: 0.80,
            widgetTransparency: 0.80,
            theme: ThemeOption.light.rawValue
        ])

        if abs(defaults.double(forKey: transparency) - 0.90) < 0.001 {
            defaults.set(0.80, forKey: transparency)
        }

        if ThemeOption(rawValue: defaults.string(forKey: theme) ?? "") == nil {
            defaults.set(ThemeOption.light.rawValue, forKey: theme)
        }
    }
}

enum ThemeOption: String, CaseIterable, Identifiable {
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .light:
            "Light"
        case .dark:
            "Dark"
        }
    }
}
