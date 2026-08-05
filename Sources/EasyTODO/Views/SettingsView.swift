import SwiftUI

struct SettingsView: View {
    @AppStorage(EasyTODOSettings.launchAtLogin) private var launchAtLogin = false
    @AppStorage(EasyTODOSettings.alwaysOnTop) private var alwaysOnTop = true
    @AppStorage(EasyTODOSettings.showMenuBar) private var showMenuBar = true
    @AppStorage(EasyTODOSettings.hiddenDockIcon) private var hiddenDockIcon = false
    @AppStorage(EasyTODOSettings.transparency) private var transparency = 0.90
    @AppStorage(EasyTODOSettings.theme) private var theme = ThemeOption.system.rawValue

    @State private var loginItemMessage: String?

    var body: some View {
        Form {
            Section("General") {
                Toggle("Launch at Login", isOn: $launchAtLogin)
                Toggle("Always on Top", isOn: $alwaysOnTop)
                Toggle("Show in Menu Bar", isOn: $showMenuBar)
                Toggle("Hide Dock Icon", isOn: $hiddenDockIcon)
                    .disabled(!showMenuBar)

                if let loginItemMessage {
                    Text(loginItemMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Transparency") {
                Picker("Window", selection: $transparency) {
                    Text("100%").tag(1.0)
                    Text("90%").tag(0.90)
                    Text("80%").tag(0.80)
                }
                .pickerStyle(.segmented)
            }

            Section("Theme") {
                Picker("Theme", selection: $theme) {
                    ForEach(ThemeOption.allCases) { option in
                        Text(option.title).tag(option.rawValue)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
        .formStyle(.grouped)
        .frame(width: 420)
        .padding()
        .onChange(of: launchAtLogin) { _, newValue in
            loginItemMessage = LoginItemManager.setEnabled(newValue)
        }
        .onChange(of: alwaysOnTop) { _, _ in
            WindowManager.shared.applyWindowSettings()
        }
        .onChange(of: transparency) { _, _ in
            WindowManager.shared.applyWindowSettings()
        }
        .onChange(of: showMenuBar) { _, newValue in
            if !newValue {
                hiddenDockIcon = false
            }

            WindowManager.shared.applyActivationPolicy()
        }
        .onChange(of: hiddenDockIcon) { _, _ in
            WindowManager.shared.applyActivationPolicy()
        }
    }
}
