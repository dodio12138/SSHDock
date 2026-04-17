// ConnectionDetailView.swift
// SSHDock

import SwiftUI
import SwiftData

struct ConnectionDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var connection: ConnectionItem
    var onDelete: (() -> Void)? = nil

    @State private var showCopied = false
    @State private var isLaunching = false
    @State private var showPassword = false
    @FocusState private var focusedField: Field?

    enum Field: Hashable { case name, host, user, port, password, key, options, tags }

    private var settings: AppSettings { AppSettings.shared }

    private var displayTitle: String {
        connection.name.isEmpty
            ? (connection.host.isEmpty ? "新连接" : connection.host)
            : connection.name
    }

    private var userHost: String {
        let u = connection.user ?? ""
        let h = connection.host.isEmpty ? "—" : connection.host
        let portPart = connection.port == 22 ? "" : ":\(connection.port)"
        return u.isEmpty ? "\(h)\(portPart)" : "\(u)@\(h)\(portPart)"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                heroHeader
                basicInfoCard
                authInfoCard
                tagsCard
                commandPreviewCard
                metadataFooter
            }
            .padding(24)
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
        .background(Color(nsColor: .textBackgroundColor).opacity(0.25))
        .navigationTitle(displayTitle)
        .navigationSubtitle(connection.host.isEmpty ? "未配置主机" : userHost)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    launch()
                } label: {
                    if isLaunching {
                        HStack(spacing: 6) {
                            ProgressView().controlSize(.small)
                            Text("启动中…")
                        }
                    } else {
                        Label("连接", systemImage: "play.fill")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(connection.host.isEmpty || isLaunching)
                .help("在终端中打开 SSH 连接 (⌘R)")
                .keyboardShortcut("r", modifiers: .command)
            }
            ToolbarItem(placement: .destructiveAction) {
                Menu {
                    Button {
                        copyCommand()
                    } label: {
                        Label("复制 SSH 命令", systemImage: "doc.on.doc")
                    }
                    Button {
                        connection.isFavorite.toggle()
                        try? modelContext.save()
                    } label: {
                        Label(connection.isFavorite ? "取消收藏" : "加入收藏",
                              systemImage: connection.isFavorite ? "star.slash" : "star")
                    }
                    Divider()
                    Button(role: .destructive) {
                        onDelete?()
                    } label: {
                        Label("删除连接", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .menuStyle(.borderlessButton)
                .help("更多操作")
            }
        }
        .onChange(of: connection.name)       { _, _ in touch() }
        .onChange(of: connection.host)       { _, _ in touch() }
        .onChange(of: connection.port)       { _, _ in touch() }
        .onChange(of: connection.user)       { _, _ in touch() }
        .onChange(of: connection.password)   { _, _ in touch() }
        .onChange(of: connection.sshKeyPath) { _, _ in touch() }
        .onChange(of: connection.sshOptions) { _, _ in touch() }
        .onChange(of: connection.tags)       { _, _ in touch() }
        .onChange(of: connection.isFavorite) { _, _ in touch() }
    }

    // MARK: - Hero

    private var heroHeader: some View {
        HStack(spacing: 16) {
            ServerAvatar(name: connection.name,
                         host: connection.host,
                         size: 64,
                         isFavorite: connection.isFavorite)

            VStack(alignment: .leading, spacing: 4) {
                Text(displayTitle)
                    .font(.title2)
                    .fontWeight(.semibold)
                Text(userHost)
                    .font(.system(.callout, design: .monospaced))
                    .foregroundColor(.secondary)
                    .textSelection(.enabled)

                if !connection.tags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(connection.tags, id: \.self) { tag in
                            TagChip(text: tag)
                        }
                    }
                    .padding(.top, 2)
                }
            }

            Spacer()

            Button {
                connection.isFavorite.toggle()
                try? modelContext.save()
            } label: {
                Image(systemName: connection.isFavorite ? "star.fill" : "star")
                    .font(.title3)
                    .foregroundColor(connection.isFavorite ? .yellow : .secondary)
            }
            .buttonStyle(.plain)
            .help(connection.isFavorite ? "取消收藏" : "加入收藏")
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.accentColor.opacity(0.08), Color.accentColor.opacity(0.02)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.accentColor.opacity(0.2), lineWidth: 0.5)
        )
    }

    // MARK: - Cards

    private var basicInfoCard: some View {
        CardSection("基本信息", icon: "server.rack") {
            inputRow("名称", icon: "tag") {
                TextField("留空则使用主机名", text: $connection.name)
                    .textFieldStyle(.plain)
                    .focused($focusedField, equals: .name)
            }
            Divider().padding(.leading, 44)
            inputRow("主机", icon: "network", required: true) {
                TextField("hostname 或 IP", text: $connection.host)
                    .textFieldStyle(.plain)
                    .focused($focusedField, equals: .host)
            }
            Divider().padding(.leading, 44)
            inputRow("用户名", icon: "person") {
                TextField("默认系统用户", text: Binding(
                    get: { connection.user ?? "" },
                    set: { connection.user = $0.isEmpty ? nil : $0 }
                ))
                .textFieldStyle(.plain)
                .focused($focusedField, equals: .user)
            }
            Divider().padding(.leading, 44)
            inputRow("端口", icon: "number") {
                HStack {
                    TextField("22", value: $connection.port, format: .number)
                        .textFieldStyle(.plain)
                        .focused($focusedField, equals: .port)
                        .frame(maxWidth: 80, alignment: .leading)
                    Stepper("", value: $connection.port, in: 1...65535)
                        .labelsHidden()
                    Spacer()
                }
            }
        }
    }

    private var authInfoCard: some View {
        CardSection("认证信息", icon: "key.fill") {
            inputRow("密码", icon: "lock") {
                HStack {
                    Group {
                        if showPassword {
                            TextField("使用密钥请留空", text: Binding(
                                get: { connection.password ?? "" },
                                set: { connection.password = $0.isEmpty ? nil : $0 }
                            ))
                        } else {
                            SecureField("使用密钥请留空", text: Binding(
                                get: { connection.password ?? "" },
                                set: { connection.password = $0.isEmpty ? nil : $0 }
                            ))
                        }
                    }
                    .textFieldStyle(.plain)
                    .focused($focusedField, equals: .password)

                    Button {
                        showPassword.toggle()
                    } label: {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help(showPassword ? "隐藏密码" : "显示密码")
                }
            }
            Divider().padding(.leading, 44)
            inputRow("私钥路径", icon: "doc.badge.gearshape") {
                HStack {
                    TextField("~/.ssh/id_ed25519", text: Binding(
                        get: { connection.sshKeyPath ?? "" },
                        set: { connection.sshKeyPath = $0.isEmpty ? nil : $0 }
                    ))
                    .textFieldStyle(.plain)
                    .focused($focusedField, equals: .key)

                    Button {
                        pickKeyFile()
                    } label: {
                        Image(systemName: "folder")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("选择文件…")
                }
            }
            Divider().padding(.leading, 44)
            inputRow("额外参数", icon: "gearshape") {
                TextField("例如：-o StrictHostKeyChecking=no", text: Binding(
                    get: { connection.sshOptions ?? "" },
                    set: { connection.sshOptions = $0.isEmpty ? nil : $0 }
                ))
                .textFieldStyle(.plain)
                .focused($focusedField, equals: .options)
            }
        }
    }

    private var tagsCard: some View {
        CardSection("标签", icon: "tag.fill") {
            inputRow("标签", icon: "tag") {
                TextField("以逗号分隔，如：web, prod", text: Binding(
                    get: { connection.tags.joined(separator: ", ") },
                    set: { connection.tags = $0.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty } }
                ))
                .textFieldStyle(.plain)
                .focused($focusedField, equals: .tags)
            }
        }
    }

    private var commandPreviewCard: some View {
        CardSection("命令预览", icon: "terminal") {
            VStack(alignment: .leading, spacing: 10) {
                ScrollView(.horizontal, showsIndicators: false) {
                    Text(previewCommand)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.primary)
                        .textSelection(.enabled)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.black.opacity(0.06))
                )

                HStack {
                    if let pw = connection.password, !pw.isEmpty {
                        Label("密码已嵌入 expect 脚本，仅本机可见", systemImage: "info.circle")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button {
                        copyCommand()
                    } label: {
                        Label(showCopied ? "已复制" : "复制命令",
                              systemImage: showCopied ? "checkmark" : "doc.on.doc")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(connection.host.isEmpty)
                }
            }
            .padding(12)
        }
    }

    private var metadataFooter: some View {
        HStack(spacing: 16) {
            metadataItem(icon: "calendar", label: "创建", value: formatDate(connection.createdAt))
            if let used = connection.lastUsedAt {
                metadataItem(icon: "clock", label: "最近使用", value: formatDate(used))
            }
            Spacer()
        }
        .font(.caption2)
        .foregroundColor(.secondary)
        .padding(.top, 4)
    }

    private func metadataItem(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text("\(label)：\(value)")
        }
    }

    @ViewBuilder
    private func inputRow<Content: View>(_ label: String,
                                          icon: String,
                                          required: Bool = false,
                                          @ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 18)
            HStack(spacing: 2) {
                Text(label).font(.callout)
                if required { Text("*").foregroundColor(.red) }
            }
            .frame(width: 72, alignment: .leading)
            content()
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    // MARK: - Actions

    private var previewCommand: String {
        (try? SSHCommandGenerator.generateSSHCommand(for: connection)) ?? "（请填写主机名）"
    }

    private func touch() {
        connection.updatedAt = Date()
    }

    private func copyCommand() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(previewCommand, forType: .string)
        withAnimation { showCopied = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { showCopied = false }
        }
    }

    private func launch() {
        guard let cmd = try? SSHCommandGenerator.generateSSHCommand(for: connection) else { return }
        connection.lastUsedAt = Date()
        try? modelContext.save()

        isLaunching = true
        Task {
            await TerminalLauncher.launch(
                command: cmd,
                preferred: settings.preferredTerminal,
                customAppName: settings.customTerminalApp.isEmpty ? nil : settings.customTerminalApp
            )
            try? await Task.sleep(nanoseconds: 500_000_000)
            isLaunching = false
        }
    }

    private func pickKeyFile() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.showsHiddenFiles = true
        panel.directoryURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".ssh")
        if panel.runModal() == .OK, let url = panel.url {
            let home = FileManager.default.homeDirectoryForCurrentUser.path
            var path = url.path
            if path.hasPrefix(home) {
                path = "~" + path.dropFirst(home.count)
            }
            connection.sshKeyPath = path
        }
    }

    private func formatDate(_ date: Date) -> String {
        let f = RelativeDateTimeFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.unitsStyle = .short
        return f.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: ConnectionItem.self, configurations: config)
    let sample = ConnectionItem(
        name: "My Server",
        host: "192.168.1.10",
        user: "ubuntu",
        port: 22,
        sshKeyPath: "~/.ssh/id_ed25519",
        tags: ["prod", "web"]
    )
    container.mainContext.insert(sample)
    return NavigationStack {
        ConnectionDetailView(connection: sample)
    }
    .modelContainer(container)
}
