import Carbon
import Foundation

final class GlobalShortcutManager: @unchecked Sendable {
    static let shared = GlobalShortcutManager()

    static let quickAddShortcutDescription = "Command-+"

    private static let quickAddSignature: OSType = 0x45545141
    private static let quickAddID: UInt32 = 1
    private static let quickAddShortcuts = [
        KeyboardShortcut(
            description: "Command-+",
            keyCode: UInt32(kVK_ANSI_Equal),
            modifiers: UInt32(cmdKey | shiftKey)
        ),
        KeyboardShortcut(
            description: "Option-Command-N",
            keyCode: UInt32(kVK_ANSI_N),
            modifiers: UInt32(cmdKey | optionKey)
        )
    ]

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private var isRegistered = false
    private(set) var registeredShortcutDescription: String?

    private init() {}

    func registerQuickAddShortcut() {
        guard !isRegistered else { return }

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let handlerStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData in
                guard let event, let userData else { return noErr }

                var hotKeyID = EventHotKeyID()
                let parameterStatus = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )

                guard parameterStatus == noErr,
                      hotKeyID.signature == GlobalShortcutManager.quickAddSignature,
                      hotKeyID.id == GlobalShortcutManager.quickAddID
                else {
                    return noErr
                }

                let manager = Unmanaged<GlobalShortcutManager>
                    .fromOpaque(userData)
                    .takeUnretainedValue()
                manager.handleQuickAddShortcut()
                return noErr
            },
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandlerRef
        )

        guard handlerStatus == noErr else {
            NSLog("EasyTODO failed to install quick add shortcut handler: \(handlerStatus)")
            return
        }

        let hotKeyID = EventHotKeyID(
            signature: Self.quickAddSignature,
            id: Self.quickAddID
        )

        for shortcut in Self.quickAddShortcuts {
            var shortcutRef: EventHotKeyRef?
            let hotKeyStatus = RegisterEventHotKey(
                shortcut.keyCode,
                shortcut.modifiers,
                hotKeyID,
                GetApplicationEventTarget(),
                0,
                &shortcutRef
            )

            if hotKeyStatus == noErr {
                hotKeyRef = shortcutRef
                registeredShortcutDescription = shortcut.description
                isRegistered = true
                NSLog("EasyTODO registered quick add shortcut: \(shortcut.description)")
                return
            }

            NSLog("EasyTODO could not register quick add shortcut \(shortcut.description): \(hotKeyStatus)")
        }

        unregisterQuickAddShortcut()
    }

    func unregisterQuickAddShortcut() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }

        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
            self.eventHandlerRef = nil
        }

        isRegistered = false
        registeredShortcutDescription = nil
    }

    private func handleQuickAddShortcut() {
        Task { @MainActor in
            QuickAddPanelManager.shared.showQuickAdd()
        }
    }
}

private struct KeyboardShortcut: Sendable {
    let description: String
    let keyCode: UInt32
    let modifiers: UInt32
}
