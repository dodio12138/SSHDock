// MenuBarController.swift
// SSHDock
//
// NSStatusItem 菜单栏控制器。
// 从 SwiftData 读取收藏 & 最近连接，构建菜单项；点击后调用 TerminalLauncher。

import AppKit
import SwiftData

@MainActor
final class MenuBarController {

    private var statusItem: NSStatusItem?
    private let modelContainer: ModelContainer
    private let settings = AppSettings.shared

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        setup()
    }

    deinit {
        if let item = statusItem {
            NSStatusBar.system.removeStatusItem(item)
        }
    }

    // MARK: - 初始化状态栏图标

    private func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem?.button?.image = NSImage(systemSymbolName: "terminal", accessibilityDescription: "SSHDock")
        statusItem?.button?.action = #selector(handleClick)
        statusItem?.button?.target = self
        statusItem?.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])

        rebuildMenu()
    }

    // MARK: - 点击重新构建菜单再弹出

    @objc private func handleClick() {
        rebuildMenu()
        statusItem?.button?.performClick(nil)
    }

    // MARK: - 构建菜单

    func rebuildMenu() {
        let menu = NSMenu()

        let connections = fetchConnections()

        // 收藏
        let favorites = connections.filter { $0.isFavorite }
        if !favorites.isEmpty {
            let favHeader = NSMenuItem(title: "⭐ 收藏", action: nil, keyEquivalent: "")
            favHeader.isEnabled = false
            menu.addItem(favHeader)
            for conn in favorites.prefix(settings.menuBarMaxItems) {
                menu.addItem(makeMenuItem(for: conn))
            }
            menu.addItem(.separator())
        }

        // 最近使用（非收藏）
        let recent = connections
            .filter { !$0.isFavorite && $0.lastUsedAt != nil }
            .sorted { ($0.lastUsedAt ?? .distantPast) > ($1.lastUsedAt ?? .distantPast) }
        if !recent.isEmpty {
            let recHeader = NSMenuItem(title: "🕐 最近使用", action: nil, keyEquivalent: "")
            recHeader.isEnabled = false
            menu.addItem(recHeader)
            for conn in recent.prefix(settings.menuBarMaxItems) {
                menu.addItem(makeMenuItem(for: conn))
            }
            menu.addItem(.separator())
        }

        // 所有连接（如果收藏+最近都为空则直接展示）
        if favorites.isEmpty && recent.isEmpty {
            if connections.isEmpty {
                let empty = NSMenuItem(title: "（暂无连接）", action: nil, keyEquivalent: "")
                empty.isEnabled = false
                menu.addItem(empty)
            } else {
                for conn in connections.prefix(settings.menuBarMaxItems) {
                    menu.addItem(makeMenuItem(for: conn))
                }
            }
            menu.addItem(.separator())
        }

        // 打开主窗口
        let openMain = NSMenuItem(title: "打开 SSHDock…", action: #selector(openMainWindow), keyEquivalent: "o")
        openMain.target = self
        menu.addItem(openMain)

        // 设置
        let openSettings = NSMenuItem(title: "设置…", action: #selector(openSettings), keyEquivalent: ",")
        openSettings.target = self
        menu.addItem(openSettings)

        menu.addItem(.separator())

        // 退出
        menu.addItem(NSMenuItem(title: "退出 SSHDock", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem?.menu = menu
    }

    // MARK: - 菜单项工厂

    private func makeMenuItem(for connection: ConnectionItem) -> NSMenuItem {
        let subtitle = connection.host.isEmpty ? "（未填写主机）" : "\(connection.host):\(connection.port)"
        let title = "\(connection.name)  —  \(subtitle)"
        let item = NSMenuItem(title: title, action: #selector(launchConnection(_:)), keyEquivalent: "")
        item.target = self
        // 用 representedObject 传递 PersistentIdentifier（先存 UUID）
        item.representedObject = connection.id.uuidString
        return item
    }

    // MARK: - 动作

    @objc private func launchConnection(_ sender: NSMenuItem) {
        guard let uuidStr = sender.representedObject as? String,
              let uuid = UUID(uuidString: uuidStr) else { return }

        let connections = fetchConnections()
        guard let conn = connections.first(where: { $0.id == uuid }) else { return }

        guard let cmd = try? SSHCommandGenerator.generateSSHCommand(for: conn) else { return }

        // 更新最近使用时间
        conn.lastUsedAt = Date()
        try? modelContainer.mainContext.save()

        Task {
            await TerminalLauncher.launch(
                command: cmd,
                preferred: settings.preferredTerminal,
                customAppName: settings.customTerminalApp.isEmpty ? nil : settings.customTerminalApp
            )
        }
    }

    @objc private func openMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        // 如果窗口已存在则直接展示
        for window in NSApp.windows where window.identifier?.rawValue == "main" {
            window.makeKeyAndOrderFront(nil)
            return
        }
        NSApp.windows.first?.makeKeyAndOrderFront(nil)
    }

    @objc private func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        // 打开 Settings scene（SwiftUI 内建命令）
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }

    // MARK: - 数据获取

    private func fetchConnections() -> [ConnectionItem] {
        let ctx = modelContainer.mainContext
        let descriptor = FetchDescriptor<ConnectionItem>(
            sortBy: [SortDescriptor(\.name)]
        )
        return (try? ctx.fetch(descriptor)) ?? []
    }
}
