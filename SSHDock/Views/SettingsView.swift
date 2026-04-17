// SettingsView.swift
// SSHDock

import SwiftUI

struct SettingsView: View {
    @ObservedObject private var settings = AppSettings.shared

    var body: some View {
        Form {
            // ── 终端 ───────────────────────────────────────
            Section("终端") {
                Picker("首选终端", selection: $settings.preferredTerminal) {
                    ForEach(PreferredTerminal.allCases) { terminal in
                        Text(terminal.displayName).tag(terminal)
                    }
                }
                .pickerStyle(.segmented)

                if settings.preferredTerminal == .custom {
                    LabeledContent("应用名称") {
                        TextField("Hyper", text: $settings.customTerminalApp)
                            .textFieldStyle(.plain)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }

            // ── SSH 默认值 ─────────────────────────────────
            Section("SSH 默认值") {
                LabeledContent("默认端口") {
                    TextField("22", value: $settings.defaultPort, format: .number)
                        .textFieldStyle(.plain)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                }
            }

            // ── 菜单栏 ─────────────────────────────────────
            Section("菜单栏") {
                LabeledContent("最多显示条数") {
                    Stepper("\(settings.menuBarMaxItems) 条",
                            value: $settings.menuBarMaxItems, in: 1...20)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 420)
        .padding()
        .navigationTitle("设置")
    }
}

#Preview {
    SettingsView()
}
