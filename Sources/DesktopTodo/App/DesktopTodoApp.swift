import SwiftData
import SwiftUI

@main
struct DesktopTodoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    private let modelContainer: ModelContainer

    @AppStorage(DesktopTodoSettings.showMenuBar) private var showMenuBar = true
    @AppStorage(DesktopTodoSettings.theme) private var theme = ThemeOption.system.rawValue

    init() {
        DesktopTodoSettings.registerDefaults()

        do {
            modelContainer = try PersistenceController.modelContainer()
        } catch {
            fatalError("Unable to create SwiftData container: \(error)")
        }
    }

    @SceneBuilder
    var body: some Scene {
        mainWindow
        menuBar
        settings
    }

    private var mainWindow: some Scene {
        WindowGroup("Desktop Todo") {
            TodoListView()
                .modelContainer(modelContainer)
                .preferredColorScheme(preferredColorScheme)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Task") {
                    NotificationCenter.default.post(name: .desktopTodoFocusNewTask, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }
    }

    private var menuBar: some Scene {
        MenuBarExtra(isInserted: $showMenuBar) {
            MenuBarTodoView()
                .modelContainer(modelContainer)
                .preferredColorScheme(preferredColorScheme)
        } label: {
            MenuBarLabelView()
                .modelContainer(modelContainer)
        }
        .menuBarExtraStyle(.window)
    }

    private var settings: some Scene {
        Settings {
            SettingsView()
                .preferredColorScheme(preferredColorScheme)
        }
    }

    private var preferredColorScheme: ColorScheme? {
        switch ThemeOption(rawValue: theme) ?? .system {
        case .system:
            nil
        case .light:
            .light
        case .dark:
            .dark
        }
    }
}
