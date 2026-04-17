// ConnectionItem.swift
// SSHDock

import Foundation
import SwiftData

/// SwiftData model that represents a saved SSH connection entry.
///
/// Note: This model stores metadata and references to key paths only. Do not
/// store private key contents or sensitive secrets here.
@Model
final class ConnectionItem: Identifiable {
    @Attribute(.unique) var id: UUID

    /// Display name for the connection (e.g. "Web Server")
    var name: String

    /// Hostname or IP (required)
    var host: String

    /// Optional user (e.g. "ubuntu")
    var user: String?

    /// SSH port (default 22)
    var port: Int

    /// Path to private key file (e.g. "~/.ssh/id_ed25519")
    var sshKeyPath: String?

    /// Optional password (will use expect script if present)
    var password: String?

    /// Additional raw ssh options (advanced users)
    var sshOptions: String?

    /// 逗号分隔字符串存储，底层 CoreData 兼容
    var tagsRaw: String

    /// 便捷计算属性，供 UI 和业务层使用
    var tags: [String] {
        get { tagsRaw.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty } }
        set { tagsRaw = newValue.joined(separator: ",") }
    }

    /// Whether this connection is favorited (shown in menu bar quickly)
    var isFavorite: Bool

    /// Last used timestamp
    var lastUsedAt: Date?

    /// Creation timestamp
    var createdAt: Date

    /// Last updated timestamp
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        host: String,
        user: String? = nil,
        port: Int = 22,
        sshKeyPath: String? = nil,
        password: String? = nil,
        sshOptions: String? = nil,
        tags: [String] = [],
        isFavorite: Bool = false,
        lastUsedAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.host = host
        self.user = user
        self.port = port
        self.sshKeyPath = sshKeyPath
        self.password = password
        self.sshOptions = sshOptions
        self.tagsRaw = tags.joined(separator: ",")
        self.isFavorite = isFavorite
        self.lastUsedAt = lastUsedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
