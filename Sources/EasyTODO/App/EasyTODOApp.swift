import SwiftData
import SwiftUI

@main
struct EasyTODOApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    private let modelContainer: ModelContainer

    @AppStorage(EasyTODOSettings.theme) private var theme = ThemeOption.light.rawValue

    init() {
        EasyTODOSettings.registerDefaults()

        do {
            modelContainer = try PersistenceController.modelContainer()
            MenuBarManager.shared.configure(modelContainer: modelContainer)
            QuickAddPanelManager.shared.configure(modelContainer: modelContainer)
            WidgetWindowManager.shared.configure(modelContainer: modelContainer)
        } catch {
            fatalError("Unable to create SwiftData container: \(error)")
        }
    }

    @SceneBuilder
    var body: some Scene {
        mainWindow
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
            CommandGroup(after: .undoRedo) {
                Button("Undo Delete") {
                    NotificationCenter.default.post(name: .easyTODOUndoDeleteTask, object: nil)
                }
                .keyboardShortcut("z", modifiers: [.control])
            }

            CommandGroup(replacing: .newItem) {
                Button("New Task") {
                    NotificationCenter.default.post(name: .easyTODOFocusNewTask, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)
            }

            CommandGroup(after: .newItem) {
                Button("Open Widget") {
                    WidgetWindowManager.shared.showWidget()
                }
            }
        }
    }

    private var settings: some Scene {
        Settings {
            SettingsView()
                .preferredColorScheme(preferredColorScheme)
        }
    }

    private var preferredColorScheme: ColorScheme? {
        switch ThemeOption(rawValue: theme) ?? .light {
        case .light:
            .light
        case .dark:
            .dark
        }
    }
}
