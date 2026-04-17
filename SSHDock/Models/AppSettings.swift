// AppSettings.swift
// SSHDock
//
// 轻量首选项，使用 UserDefaults 持久化。
// 与 TerminalLauncher 和 MenuBarController 共享。

import Foundation
import Combine

final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    // 首选终端
    @Published var preferredTerminal: PreferredTerminal {
        didSet { UserDefaults.standard.set(preferredTerminal.rawValue, forKey: Keys.preferredTerminal) }
    }

    // 自定义终端应用名称（当 preferredTerminal == .custom 时使用）
    @Published var customTerminalApp: String {
        didSet { UserDefaults.standard.set(customTerminalApp, forKey: Keys.customTerminalApp) }
    }

    // 默认 SSH 端口（全局默认；单条连接可覆盖）
    @Published var defaultPort: Int {
        didSet { UserDefaults.standard.set(defaultPort, forKey: Keys.defaultPort) }
    }

    // 菜单栏最多显示多少条收藏/最近连接
    @Published var menuBarMaxItems: Int {
        didSet { UserDefaults.standard.set(menuBarMaxItems, forKey: Keys.menuBarMaxItems) }
    }

    private init() {
        let raw = UserDefaults.standard.string(forKey: Keys.preferredTerminal) ?? ""
        preferredTerminal = PreferredTerminal(rawValue: raw) ?? .terminal
        customTerminalApp = UserDefaults.standard.string(forKey: Keys.customTerminalApp) ?? ""
        defaultPort = UserDefaults.standard.integer(forKey: Keys.defaultPort).nonZero ?? 22
        menuBarMaxItems = UserDefaults.standard.integer(forKey: Keys.menuBarMaxItems).nonZero ?? 10
    }

    private enum Keys {
        static let preferredTerminal = "preferredTerminal"
        static let customTerminalApp = "customTerminalApp"
        static let defaultPort       = "defaultPort"
        static let menuBarMaxItems   = "menuBarMaxItems"
    }
}

private extension Int {
    var nonZero: Int? { self == 0 ? nil : self }
}
