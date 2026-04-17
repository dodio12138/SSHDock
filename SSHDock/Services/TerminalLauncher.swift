// TerminalLauncher.swift
// SSHDock

import Foundation
import AppKit

// MARK: - 错误

enum TerminalLauncherError: Error, LocalizedError {
    case launchFailed(String)
    case noTerminalFound
    case commandGenerationFailed(Error)

    var errorDescription: String? {
        switch self {
        case .launchFailed(let msg): return "终端启动失败：\(msg)"
        case .noTerminalFound: return "未找到可用的终端应用"
        case .commandGenerationFailed(let err): return "命令生成失败：\(err.localizedDescription)"
        }
    }
}

// MARK: - 首选终端枚举（与 AppSettings 同步）

enum PreferredTerminal: String, CaseIterable, Identifiable {
    case terminal = "Terminal"
    case iterm    = "iTerm"
    case custom   = "自定义"

    var id: String { rawValue }
    var displayName: String { rawValue }
}

// MARK: - 主入口

struct TerminalLauncher {

    static func launch(command: String,
                       preferred: PreferredTerminal,
                       customAppName: String? = nil) async {
        // 把长命令写入临时脚本，Terminal 里只显示一行干净的 `bash /tmp/xxx.sh; exit`
        let wrappedCommand = wrapInTempScript(command)

        let result: Result<Void, TerminalLauncherError>

        switch preferred {
        case .terminal:
            result = await openInTerminalApp(command: wrappedCommand)
        case .iterm:
            result = await openInITerm(command: wrappedCommand)
        case .custom:
            let app = customAppName ?? "Terminal"
            result = await openInGenericApp(appName: app, command: wrappedCommand)
        }

        if case .failure = result, preferred != .terminal {
            let fallback = await openInTerminalApp(command: wrappedCommand)
            if case .failure = fallback {
                copyToClipboard(command)
                await showCopiedAlert()
            }
        }

        if case .failure(let err) = result {
            print("[TerminalLauncher] 警告: \(err.localizedDescription)")
        }
    }

    /// 把任意 shell 命令写入临时脚本，返回一个极短的、能被 `do script` 优雅显示的启动命令。
    /// 脚本首行 `clear` 会把 Terminal.app 自己回显的那行启动命令也擦掉。
    static func wrapInTempScript(_ command: String) -> String {
        let path = "/tmp/sshdock_\(UUID().uuidString).sh"
        // printf '\033c' 重置终端，'\e[3J' 清除 scrollback，让用户完全看不到前面的启动噪音
        let script = """
        #!/bin/bash
        printf '\\033c\\033[3J'
        \(command)
        EXIT_CODE=$?
        rm -f "\(path)"
        exit $EXIT_CODE
        """
        do {
            try script.write(toFile: path, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: 0o755],
                                                  ofItemAtPath: path)
        } catch {
            // 写入失败则直接返回原命令
            return command
        }
        // 只显示最后这一段，而脚本首行的 reset 会立刻把它也抹掉
        return "printf '\\033c\\033[3J';bash \(path)"
    }

    // MARK: - Terminal.app

    static func openInTerminalApp(command: String) async -> Result<Void, TerminalLauncherError> {
        let escaped = appleScriptEscape(command)
        let script = """
        tell application "Terminal"
            activate
            do script \(escaped)
        end tell
        """
        return await runAppleScript(script)
    }

    // MARK: - iTerm2

    static func openInITerm(command: String) async -> Result<Void, TerminalLauncherError> {
        let escaped = appleScriptEscape(command)
        let script = """
        tell application "iTerm"
            activate
            create window with default profile
            tell current session of current window
                write text \(escaped)
            end tell
        end tell
        """
        return await runAppleScript(script)
    }

    // MARK: - 通用应用

    static func openInGenericApp(appName: String, command: String) async -> Result<Void, TerminalLauncherError> {
        let escaped = appleScriptEscape(command)
        let script = """
        tell application "\(appName)"
            activate
            do script \(escaped)
        end tell
        """
        return await runAppleScript(script)
    }

    // MARK: - AppleScript 执行引擎

    @discardableResult
    static func runAppleScript(_ source: String) async -> Result<Void, TerminalLauncherError> {
        return await withCheckedContinuation { cont in
            DispatchQueue.global(qos: .userInitiated).async {
                var error: NSDictionary?
                let script = NSAppleScript(source: source)
                script?.executeAndReturnError(&error)
                if let err = error {
                    let msg = err[NSAppleScript.errorMessage] as? String ?? "未知错误"
                    // 返回详细的 AppleScript 错误
                    cont.resume(returning: .failure(.launchFailed(msg)))
                } else {
                    cont.resume(returning: .success(()))
                }
            }
        }
    }

    // MARK: - 工具

    static func appleScriptEscape(_ s: String) -> String {
        let escaped = s
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        return "\"\(escaped)\""
    }

    static func copyToClipboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    @MainActor
    static func showCopiedAlert() {
        let alert = NSAlert()
        alert.messageText = "无法启动终端"
        alert.informativeText = "SSH 命令已复制到剪贴板，请手动粘贴到终端中执行。"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "好的")
        alert.runModal()
    }
}
