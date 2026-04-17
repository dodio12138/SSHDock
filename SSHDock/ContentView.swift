//
//  ContentView.swift
//  SSHDock
//

import SwiftUI
import SwiftData
import Combine

// MARK: - 新建连接 Sheet 用的草稿对象
final class NewConnectionDraft: ObservableObject {
    @Published var name        = ""
    @Published var host        = ""
    @Published var user        = ""
    @Published var port        = 22
    @Published var sshKeyPath  = ""
    @Published var password    = ""
    @Published var sshOptions  = ""
    @Published var tags        = ""
    @Published var isFavorite  = false

    var isValid: Bool { !host.trimmingCharacters(in: .whitespaces).isEmpty }

    func apply(to item: ConnectionItem) {
        item.name       = name.isEmpty ? host : name
        item.host       = host.trimmingCharacters(in: .whitespaces)
        item.user       = user.isEmpty ? nil : user
        item.port       = port
        item.sshKeyPath = sshKeyPath.isEmpty ? nil : sshKeyPath
        item.password   = password.isEmpty ? nil : password
        item.sshOptions = sshOptions.isEmpty ? nil : sshOptions
        item.tags       = tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        item.isFavorite = isFavorite
    }
}

// MARK: - 列表分组

private enum ListSection: String, CaseIterable, Identifiable {
    case favorites = "收藏"
    case recents   = "最近使用"
    case all       = "全部连接"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .favorites: return "star.fill"
        case .recents:   return "clock.fill"
        case .all:       return "server.rack"
        }
    }
}

// MARK: - ContentView

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ConnectionItem.name) private var connections: [ConnectionItem]

    @State private var selectedID: PersistentIdentifier?
    @State private var searchText = ""
    @State private var showNewSheet = false
    @State private var draftID = UUID()

    @State private var itemToDelete: ConnectionItem?
    @State private var showDeleteAlert = false

    // Toast
    @State private var toastText: String?
    @State private var toastIcon: String = "checkmark.circle.fill"

    private var filtered: [ConnectionItem] {
        if searchText.isEmpty { return connections }
        return connections.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.host.localizedCaseInsensitiveContains(searchText) ||
            $0.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }

    private var favorites: [ConnectionItem] {
        filtered.filter(\.isFavorite)
    }
    private var recents: [ConnectionItem] {
        filtered
            .filter { $0.lastUsedAt != nil && !$0.isFavorite }
            .sorted { ($0.lastUsedAt ?? .distantPast) > ($1.lastUsedAt ?? .distantPast) }
            .prefix(5)
            .map { $0 }
    }
    private var others: [ConnectionItem] {
        let shown = Set(favorites.map(\.id)).union(recents.map(\.id))
        return filtered.filter { !shown.contains($0.id) }
    }

    private var currentItem: ConnectionItem? {
        guard let id = selectedID else { return nil }
        return connections.first(where: { $0.id == id })
    }

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detail
                // 切换选中时强制重建详情页，避免 @State（如密码显示、编辑焦点）残留
                .id(selectedID)
        }
        .frame(minWidth: 860, minHeight: 540)
        .sheet(isPresented: $showNewSheet) {
            NewConnectionSheet(draft: NewConnectionDraft()) { save, draft in
                if save {
                    let item = ConnectionItem(name: "", host: "")
                    draft.apply(to: item)
                    modelContext.insert(item)
                    try? modelContext.save()
                    selectedID = item.id
                    showToast(icon: "checkmark.circle.fill", text: "已创建「\(item.name)」")
                }
                showNewSheet = false
            }
            .id(draftID)
        }
        .alert("删除连接", isPresented: $showDeleteAlert, presenting: itemToDelete) { item in
            Button("删除", role: .destructive) { delete(item) }
            Button("取消", role: .cancel) {}
        } message: { item in
            Text("确定要删除「\(item.name)」吗？此操作不可撤销。")
        }
        .overlay(alignment: .bottom) {
            if let text = toastText {
                Toast(icon: toastIcon, text: text)
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: toastText)
    }

    // MARK: - Sidebar

    @ViewBuilder
    private var sidebar: some View {
        ZStack {
            // 点击侧栏空白区域 → 取消选中
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { selectedID = nil }

            List(selection: $selectedID) {
                if !favorites.isEmpty {
                    sectionView(.favorites, items: favorites)
                }
                if !recents.isEmpty {
                    sectionView(.recents, items: recents)
                }
                if !others.isEmpty {
                    sectionView(.all, items: others)
                }
                if connections.isEmpty {
                    emptySidebarHint
                } else if filtered.isEmpty {
                    noSearchResultsHint
                }

                // 列表底部占位 —— 点击这里也会清空选中
                Color.clear
                    .frame(height: 120)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .contentShape(Rectangle())
                    .onTapGesture { selectedID = nil }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("SSHDock")
        .searchable(text: $searchText, placement: .sidebar, prompt: "搜索连接、主机或标签")
        .navigationSplitViewColumnWidth(min: 240, ideal: 280)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    draftID = UUID()
                    showNewSheet = true
                } label: {
                    Label("新建连接", systemImage: "plus")
                }
                .help("新建 SSH 连接 (⌘N)")
                .keyboardShortcut("n", modifiers: .command)
            }
        }
        .onDeleteCommand {
            if let item = currentItem {
                itemToDelete = item
                showDeleteAlert = true
            }
        }
    }

    @ViewBuilder
    private func sectionView(_ section: ListSection, items: [ConnectionItem]) -> some View {
        Section {
            ForEach(items) { connection in
                ConnectionRowView(connection: connection,
                                  isSelected: selectedID == connection.id) {
                    launchConnection(connection)
                }
                .tag(connection.id)
                .listRowInsets(EdgeInsets(top: 2, leading: 6, bottom: 2, trailing: 6))
                .contextMenu {
                    Button {
                        launchConnection(connection)
                    } label: {
                        Label("连接", systemImage: "play.fill")
                    }
                    Button {
                        selectedID = connection.id
                    } label: {
                        Label("编辑", systemImage: "pencil")
                    }
                    Button {
                        connection.isFavorite.toggle()
                        try? modelContext.save()
                    } label: {
                        Label(connection.isFavorite ? "取消收藏" : "加入收藏",
                              systemImage: connection.isFavorite ? "star.slash" : "star")
                    }
                    Button {
                        copyCommand(connection)
                    } label: {
                        Label("复制 SSH 命令", systemImage: "doc.on.doc")
                    }
                    Divider()
                    Button(role: .destructive) {
                        itemToDelete = connection
                        showDeleteAlert = true
                    } label: {
                        Label("删除", systemImage: "trash")
                    }
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        itemToDelete = connection
                        showDeleteAlert = true
                    } label: {
                        Label("删除", systemImage: "trash")
                    }
                }
            }
        } header: {
            HStack(spacing: 6) {
                Image(systemName: section.icon)
                    .font(.system(size: 10, weight: .semibold))
                Text(section.rawValue)
                    .font(.system(size: 11, weight: .semibold))
                Spacer()
                Text("\(items.count)")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .textCase(nil)
        }
    }

    private var emptySidebarHint: some View {
        VStack(spacing: 8) {
            Image(systemName: "tray")
                .font(.largeTitle)
                .foregroundColor(.secondary.opacity(0.5))
            Text("还没有连接")
                .font(.callout)
                .foregroundColor(.secondary)
            Text("点击右上角 + 添加第一个连接")
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .listRowBackground(Color.clear)
    }

    private var noSearchResultsHint: some View {
        VStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.title2)
                .foregroundColor(.secondary)
            Text("未找到匹配的连接")
                .font(.callout)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .listRowBackground(Color.clear)
    }

    // MARK: - Detail

    @ViewBuilder
    private var detail: some View {
        if let item = currentItem {
            ConnectionDetailView(connection: item) {
                itemToDelete = item
                showDeleteAlert = true
            }
        } else {
            emptyDetailView
        }
    }

    private var emptyDetailView: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.accentColor.opacity(0.2), .accentColor.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 110, height: 110)
                Image(systemName: "terminal.fill")
                    .font(.system(size: 46))
                    .foregroundStyle(
                        LinearGradient(colors: [.accentColor, .accentColor.opacity(0.7)],
                                       startPoint: .top, endPoint: .bottom)
                    )
            }

            VStack(spacing: 6) {
                Text("SSHDock")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text(connections.isEmpty
                     ? "一个更直观的 SSH 入口管理工具"
                     : "从左侧选择一个连接，或新建一个")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }

            Button {
                draftID = UUID()
                showNewSheet = true
            } label: {
                Label("新建连接", systemImage: "plus.circle.fill")
                    .font(.callout)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut("n", modifiers: .command)

            if !connections.isEmpty {
                Text("提示：双击左侧条目可直接启动连接")
                    .font(.caption)
                    .foregroundColor(.secondary.opacity(0.8))
                    .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .textBackgroundColor).opacity(0.3))
        .navigationTitle("SSHDock")
        .navigationSubtitle(connections.isEmpty ? "" : "\(connections.count) 个连接")
    }

    // MARK: - Actions

    private func delete(_ item: ConnectionItem) {
        let name = item.name
        if selectedID == item.id { selectedID = nil }
        modelContext.delete(item)
        try? modelContext.save()
        showToast(icon: "trash.fill", text: "已删除「\(name)」")
    }

    private func launchConnection(_ item: ConnectionItem) {
        guard let cmd = try? SSHCommandGenerator.generateSSHCommand(for: item) else {
            showToast(icon: "exclamationmark.triangle.fill", text: "命令生成失败")
            return
        }
        item.lastUsedAt = Date()
        try? modelContext.save()
        let settings = AppSettings.shared
        Task {
            await TerminalLauncher.launch(
                command: cmd,
                preferred: settings.preferredTerminal,
                customAppName: settings.customTerminalApp.isEmpty ? nil : settings.customTerminalApp
            )
        }
        showToast(icon: "play.circle.fill", text: "正在启动「\(item.name)」")
    }

    private func copyCommand(_ item: ConnectionItem) {
        guard let cmd = try? SSHCommandGenerator.generateSSHCommand(for: item) else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(cmd, forType: .string)
        showToast(icon: "doc.on.doc.fill", text: "命令已复制")
    }

    private func showToast(icon: String, text: String) {
        toastIcon = icon
        toastText = text
        let captured = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if toastText == captured { toastText = nil }
        }
    }
}

// MARK: - Row

private struct ConnectionRowView: View {
    let connection: ConnectionItem
    let isSelected: Bool
    let onLaunch: () -> Void

    @State private var isHovering = false

    private var subtitle: String {
        var parts: [String] = []
        if let u = connection.user, !u.isEmpty { parts.append("\(u)@\(connection.host)") }
        else { parts.append(connection.host.isEmpty ? "（未填写主机）" : connection.host) }
        if connection.port != 22 { parts.append(":\(connection.port)") }
        return parts.joined()
    }

    var body: some View {
        HStack(spacing: 10) {
            ServerAvatar(name: connection.name,
                         host: connection.host,
                         size: 32,
                         isFavorite: connection.isFavorite)

            VStack(alignment: .leading, spacing: 2) {
                Text(connection.name.isEmpty ? connection.host : connection.name)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                if !connection.tags.isEmpty {
                    HStack(spacing: 3) {
                        ForEach(connection.tags.prefix(3), id: \.self) { tag in
                            TagChip(text: tag)
                        }
                        if connection.tags.count > 3 {
                            Text("+\(connection.tags.count - 3)")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 2)
                }
            }

            Spacer(minLength: 4)

            // Hover 时出现的快速连接按钮（选中时也显示，更方便）
            if isHovering || isSelected {
                Button(action: onLaunch) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 22, height: 22)
                        .background(Circle().fill(Color.accentColor))
                }
                .buttonStyle(.plain)
                .help("启动连接")
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(rowBackground)
        )
        .contentShape(Rectangle())
        .onTapGesture(count: 2) { onLaunch() }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.12)) {
                isHovering = hovering
            }
        }
    }

    private var rowBackground: Color {
        if isSelected { return Color.clear }  // 系统选中高亮已覆盖
        if isHovering { return Color.primary.opacity(0.07) }
        return Color.clear
    }
}

// MARK: - 新建连接 Sheet

private struct NewConnectionSheet: View {
    @StateObject var draft: NewConnectionDraft
    var onDismiss: (Bool, NewConnectionDraft) -> Void

    @FocusState private var focusedField: Field?

    enum Field: Hashable { case name, host, user, port, password, key, options, tags }

    var body: some View {
        VStack(spacing: 0) {
            // Hero 头部
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            LinearGradient(colors: [.accentColor, .accentColor.opacity(0.6)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 44, height: 44)
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("新建 SSH 连接")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("填写连接信息，带 * 的字段为必填")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(20)

            Divider()

            // 表单
            ScrollView {
                VStack(spacing: 18) {
                    CardSection("基本信息", icon: "server.rack") {
                        input("名称", systemImage: "tag") {
                            TextField("留空则使用主机名", text: $draft.name)
                                .textFieldStyle(.plain)
                                .focused($focusedField, equals: .name)
                        }
                        inputDivider()
                        input("主机", systemImage: "network", required: true) {
                            TextField("hostname 或 IP", text: $draft.host)
                                .textFieldStyle(.plain)
                                .focused($focusedField, equals: .host)
                        }
                        inputDivider()
                        input("用户名", systemImage: "person") {
                            TextField("默认系统用户", text: $draft.user)
                                .textFieldStyle(.plain)
                                .focused($focusedField, equals: .user)
                        }
                        inputDivider()
                        input("端口", systemImage: "number") {
                            HStack {
                                TextField("22", value: $draft.port, format: .number)
                                    .textFieldStyle(.plain)
                                    .focused($focusedField, equals: .port)
                                Stepper("", value: $draft.port, in: 1...65535)
                                    .labelsHidden()
                            }
                        }
                    }

                    CardSection("认证信息", icon: "key.fill") {
                        input("密码", systemImage: "lock") {
                            SecureField("使用密钥请留空", text: $draft.password)
                                .textFieldStyle(.plain)
                                .focused($focusedField, equals: .password)
                        }
                        inputDivider()
                        input("私钥路径", systemImage: "doc.badge.gearshape") {
                            TextField("~/.ssh/id_ed25519", text: $draft.sshKeyPath)
                                .textFieldStyle(.plain)
                                .focused($focusedField, equals: .key)
                        }
                        inputDivider()
                        input("额外参数", systemImage: "gearshape") {
                            TextField("例如：-o StrictHostKeyChecking=no", text: $draft.sshOptions)
                                .textFieldStyle(.plain)
                                .focused($focusedField, equals: .options)
                        }
                    }

                    CardSection("标签 & 收藏", icon: "tag.fill") {
                        input("标签", systemImage: "tag") {
                            TextField("以逗号分隔，如：web, prod", text: $draft.tags)
                                .textFieldStyle(.plain)
                                .focused($focusedField, equals: .tags)
                        }
                        inputDivider()
                        HStack {
                            Label("加入收藏", systemImage: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.callout)
                            Spacer()
                            Toggle("", isOn: $draft.isFavorite).labelsHidden()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                    }
                }
                .padding(20)
            }

            Divider()

            // 底部按钮
            HStack {
                Text(draft.isValid ? "准备就绪" : "请填写主机")
                    .font(.caption)
                    .foregroundColor(draft.isValid ? .green : .secondary)
                Spacer()
                Button("取消") { onDismiss(false, draft) }
                    .keyboardShortcut(.escape, modifiers: [])
                Button {
                    onDismiss(true, draft)
                } label: {
                    Label("添加", systemImage: "checkmark")
                        .frame(minWidth: 60)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!draft.isValid)
                .keyboardShortcut(.return, modifiers: .command)
            }
            .padding(16)
        }
        .frame(width: 520, height: 620)
        .onAppear { focusedField = .host }
    }

    @ViewBuilder
    private func input<Content: View>(_ label: String,
                                      systemImage: String,
                                      required: Bool = false,
                                      @ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .foregroundColor(.secondary)
                .frame(width: 16)
            HStack(spacing: 2) {
                Text(label)
                if required {
                    Text("*").foregroundColor(.red)
                }
            }
            .font(.callout)
            .frame(width: 70, alignment: .leading)
            content()
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private func inputDivider() -> some View {
        Divider().padding(.leading, 44)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: ConnectionItem.self, inMemory: true)
}
