import AppKit
import SwiftData
import SwiftUI

@MainActor
final class MenuBarManager: NSObject {
    static let shared = MenuBarManager()

    private var modelContainer: ModelContainer?
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var refreshTimer: Timer?
    private var defaultsObserver: NSObjectProtocol?
    private var pendingSingleClick: DispatchWorkItem?

    private override init() {
        super.init()
    }

    func configure(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        observeSettings()
        syncVisibility()
    }

    func closePopover() {
        pendingSingleClick?.cancel()
        pendingSingleClick = nil
        popover?.performClose(nil)
    }

    private func observeSettings() {
        guard defaultsObserver == nil else { return }

        defaultsObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.syncVisibility()
                self?.refreshStatusTitle()
            }
        }
    }

    private func syncVisibility() {
        if UserDefaults.standard.bool(forKey: EasyTODOSettings.showMenuBar) {
            installStatusItem()
        } else {
            removeStatusItem()
        }
    }

    private func installStatusItem() {
        guard statusItem == nil else {
            refreshStatusTitle()
            return
        }

        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.statusItem = statusItem

        if let button = statusItem.button {
            button.target = self
            button.action = #selector(handleStatusItemClick(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.toolTip = "EasyTODO"
        }

        refreshStatusTitle()
        startRefreshTimer()
    }

    private func removeStatusItem() {
        pendingSingleClick?.cancel()
        pendingSingleClick = nil
        popover?.performClose(nil)
        popover = nil
        stopRefreshTimer()

        if let statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
            self.statusItem = nil
        }
    }

    @objc private func handleStatusItemClick(_ sender: NSStatusBarButton) {
        refreshStatusTitle()

        if NSApp.currentEvent?.type == .rightMouseUp {
            pendingSingleClick?.cancel()
            pendingSingleClick = nil
            popover?.performClose(nil)
            showContextMenu(relativeTo: sender)
            return
        }

        guard NSApp.currentEvent?.clickCount ?? 1 < 2 else {
            pendingSingleClick?.cancel()
            pendingSingleClick = nil
            popover?.performClose(nil)
            WindowManager.shared.showMainWindow()
            return
        }

        pendingSingleClick?.cancel()

        let click = DispatchWorkItem { [weak self, weak sender] in
            guard let self, let sender else { return }
            self.togglePopover(relativeTo: sender)
        }
        pendingSingleClick = click
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18, execute: click)
    }

    private func showContextMenu(relativeTo button: NSStatusBarButton) {
        guard let statusItem else { return }

        let menu = NSMenu()

        let showItem = NSMenuItem(title: "Show", action: #selector(showFromMenu(_:)), keyEquivalent: "")
        showItem.target = self
        menu.addItem(showItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitFromMenu(_:)), keyEquivalent: "")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
        button.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func showFromMenu(_ sender: NSMenuItem) {
        popover?.performClose(nil)
        WindowManager.shared.showMainWindow()
    }

    @objc private func quitFromMenu(_ sender: NSMenuItem) {
        NSApp.terminate(nil)
    }

    private func togglePopover(relativeTo button: NSStatusBarButton) {
        if let popover, popover.isShown {
            popover.performClose(nil)
            return
        }

        let popover = makePopover()
        self.popover = popover
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        refreshStatusTitle()
    }

    private func makePopover() -> NSPopover {
        let popover = NSPopover()
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 260, height: 360)

        if let modelContainer {
            popover.contentViewController = NSHostingController(
                rootView: MenuBarTodoView()
                    .modelContainer(modelContainer)
                    .preferredColorScheme(preferredColorScheme)
            )
        }

        return popover
    }

    private func refreshStatusTitle() {
        guard let button = statusItem?.button, let modelContainer else { return }

        do {
            let context = modelContainer.mainContext
            _ = try TaskDayMaintenance.rolloverUnfinishedTasksToToday(in: context)
            let tasks = try context.fetch(FetchDescriptor<TodoTask>())
            let todayTasks = tasks.filter { task in
                task.isScheduled(on: .now)
            }
            let completedCount = todayTasks.filter(\.isCompleted).count
            button.title = "\(completedCount) / \(todayTasks.count)"
        } catch {
            button.title = "- / -"
            NSLog("EasyTODO failed to refresh menu bar status: \(error)")
        }
    }

    private func startRefreshTimer() {
        guard refreshTimer == nil else { return }

        refreshTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refreshStatusTitle()
            }
        }
    }

    private func stopRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    private var preferredColorScheme: ColorScheme {
        switch ThemeOption(rawValue: UserDefaults.standard.string(forKey: EasyTODOSettings.theme) ?? "") ?? .light {
        case .light:
            .light
        case .dark:
            .dark
        }
    }
}
