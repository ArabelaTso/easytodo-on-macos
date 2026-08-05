import SwiftData
import SwiftUI

@main
struct EasyTODOApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    private let modelContainer: ModelContainer

    @AppStorage(EasyTODOSettings.showMenuBar) private var showMenuBar = true
    @AppStorage(EasyTODOSettings.theme) private var theme = ThemeOption.system.rawValue

    init() {
        EasyTODOSettings.registerDefaults()

        do {
            modelContainer = try PersistenceController.modelContainer()
            QuickAddPanelManager.shared.configure(modelContainer: modelContainer)
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
        WindowGroup("EasyTODO") {
            TodoListView()
                .modelContainer(modelContainer)
                .preferredColorScheme(preferredColorScheme)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Task") {
                    NotificationCenter.default.post(name: .easyTODOFocusNewTask, object: nil)
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
