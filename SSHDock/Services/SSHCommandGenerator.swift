// SSHCommandGenerator.swift
// SSHDock

import Foundation

// MARK: - Errors

enum CommandGenerationError: Error, LocalizedError, Equatable {
    case emptyHost
    case invalidPort(Int)
    case invalidKeyPath(String)

    var errorDescription: String? {
        switch self {
        case .emptyHost:
            return "主机名不能为空"
        case .invalidPort(let p):
            return "端口号无效：\(p)（应在 1-65535 之间）"
        case .invalidKeyPath(let path):
            return "私钥路径无效：\(path)"
        }
    }
}

// MARK: - Generator

struct SSHCommandGenerator {

    static func generateSSHCommand(
        for item: ConnectionItem,
        additionalArgs: [String] = []
    ) throws -> String {
        try validate(item)

        var parts = ["ssh"]

        if let keyPath = item.sshKeyPath, !keyPath.isEmpty {
            parts += ["-i", shellEscape(expandTilde(keyPath))]
        }

        if item.port != 22 {
            parts += ["-p", "\(item.port)"]
        }

        if let opts = item.sshOptions, !opts.isEmpty {
            parts.append(opts)
        }

        parts.append(userHost(item))

        if !additionalArgs.isEmpty {
            parts.append("--")
            parts += additionalArgs.map { shellEscape($0) }
        }

        let baseCmd = parts.joined(separator: " ")

        // 有密码时用 expect 脚本 + base64 编码方式传递，避免所有引号嵌套问题
        if let pwd = item.password, !pwd.isEmpty {
            // Tcl 双引号内需要转义的字符
            let tclPwd = pwd
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "\"", with: "\\\"")
                .replacingOccurrences(of: "$", with: "\\$")
                .replacingOccurrences(of: "[", with: "\\[")
                .replacingOccurrences(of: "]", with: "\\]")

            // 构造完整的 expect 脚本内容（注意使用 \r 字面两字符，Tcl 会解释为 CR）
            // log_user 0 抑制 spawn 回显与密码提示；发送密码后 log_user 1 再把控制权交还用户
            let expectScript = """
            log_user 0
            set timeout 60
            spawn \(baseCmd)
            expect {
                "*(yes/no)*" { send "yes\\r"; exp_continue }
                "*assword:*" { send "\(tclPwd)\\r" }
                "*assphrase*" { send "\(tclPwd)\\r" }
            }
            log_user 1
            interact
            """

            // base64 编码，彻底避免 shell / AppleScript 的各种引号嵌套难题
            let base64 = expectScript.data(using: .utf8)!.base64EncodedString()

            // 单行 bash 命令：解码写入临时文件 → expect 执行 → 清理
            return "F=/tmp/sshdock_$$_$RANDOM.exp; echo \(base64) | base64 -d > \"$F\"; /usr/bin/expect -f \"$F\"; rm -f \"$F\""
        }

        return baseCmd
    }

    static func generateSSHArguments(
        for item: ConnectionItem,
        additionalArgs: [String] = []
    ) throws -> [String] {
        try validate(item)

        var args: [String] = []

        if let keyPath = item.sshKeyPath, !keyPath.isEmpty {
            args += ["-i", expandTilde(keyPath)]
        }

        if item.port != 22 {
            args += ["-p", "\(item.port)"]
        }

        if let opts = item.sshOptions, !opts.isEmpty {
            args += opts.split(separator: " ").map(String.init)
        }

        args.append(userHost(item))

        if !additionalArgs.isEmpty {
            args.append("--")
            args += additionalArgs
        }

        return args
    }

    // MARK: SCP

    static func generateSCPUploadCommand(
        for item: ConnectionItem,
        localPath: String,
        remotePath: String
    ) throws -> String {
        try validate(item)
        guard !localPath.isEmpty else { throw CommandGenerationError.invalidKeyPath(localPath) }

        var parts = ["scp"]

        if let keyPath = item.sshKeyPath, !keyPath.isEmpty {
            parts += ["-i", shellEscape(expandTilde(keyPath))]
        }

        if item.port != 22 {
            parts += ["-P", "\(item.port)"]
        }

        parts.append(shellEscape(localPath))
        parts.append("\(userHost(item)):\(shellEscape(remotePath))")

        return parts.joined(separator: " ")
    }

    // MARK: - Helpers

    static func userHost(_ item: ConnectionItem) -> String {
        if let user = item.user, !user.isEmpty {
            return "\(user)@\(item.host)"
        }
        return item.host
    }

    static func expandTilde(_ path: String) -> String {
        if path.hasPrefix("~/") {
            let home = FileManager.default.homeDirectoryForCurrentUser.path
            return home + path.dropFirst(1)
        }
        return path
    }

    static func shellEscape(_ s: String) -> String {
        let escaped = s.replacingOccurrences(of: "'", with: "'\\''")
        return "'\(escaped)'"
    }

    // MARK: - Validation

    static func validate(_ item: ConnectionItem) throws {
        guard !item.host.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw CommandGenerationError.emptyHost
        }
        guard (1...65535).contains(item.port) else {
            throw CommandGenerationError.invalidPort(item.port)
        }
    }
}
