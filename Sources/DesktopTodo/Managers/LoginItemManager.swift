import Foundation
import ServiceManagement

@MainActor
enum LoginItemManager {
    static func setEnabled(_ isEnabled: Bool) -> String? {
        do {
            if isEnabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }

            return nil
        } catch {
            return "Launch at Login could not be updated for this build: \(error.localizedDescription)"
        }
    }
}
