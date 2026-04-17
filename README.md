# SSHDock

一个面向 macOS 的 SSH 登录入口管理工具，让你以更直观的方式保存、命名、备注和分类 SSH 连接，一键启动到 Terminal / iTerm。

![macOS](https://img.shields.io/badge/macOS-13%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![SwiftUI](https://img.shields.io/badge/SwiftUI-%E2%9C%93-green)

## ✨ 特性

- 🖥 **原生 macOS 体验** — Swift + SwiftUI + AppKit 构建
- 📂 **连接管理** — 名称、主机、用户、端口、密钥路径、标签、收藏
- 🔐 **密码直连** — 通过 expect 自动注入密码，无需每次手输
- ⭐ **收藏 & 最近使用** — 侧边栏按组展示，常用连接一眼可见
- 🔍 **快速搜索** — 按名称 / 主机 / 标签模糊匹配
- 🍎 **菜单栏快捷启动** — 点击状态栏图标即可打开收藏的连接
- 🎨 **现代化 UI** — 服务器彩色头像、Hover 反馈、Toast 提示、卡片化表单
- ⌨️ **快捷键** — ⌘N 新建、⌘R 启动、⌘F 搜索、⌘, 设置
- 🚀 **多终端支持** — Terminal.app / iTerm2 / 自定义终端应用

## 📦 技术栈

| 层 | 技术 |
|----|------|
| 数据持久化 | SwiftData |
| UI | SwiftUI |
| 菜单栏 | AppKit NSStatusItem |
| 终端拉起 | AppleScript + 临时脚本 |
| 密码自动化 | macOS 内置 expect |

## 🏗 架构

```
SSHDock/
├── Models/
│   ├── ConnectionItem.swift       # SwiftData 连接模型
│   └── AppSettings.swift          # UserDefaults 首选项
├── Services/
│   ├── SSHCommandGenerator.swift  # SSH / SCP 命令拼装
│   └── TerminalLauncher.swift     # 终端拉起
├── Controllers/
│   └── MenuBarController.swift    # NSStatusItem 菜单栏
├── Views/
│   ├── ConnectionDetailView.swift # 详情与编辑页
│   ├── SettingsView.swift         # 设置面板
│   └── UIComponents.swift         # 通用组件（头像、Chip、Toast）
└── ContentView.swift              # 主窗口
```

## 🚀 开始使用

### 要求

- macOS 13.0 或更高
- Xcode 15 或更高

### 构建运行

```bash
git clone https://github.com/<your-username>/SSHDock.git
cd SSHDock
open SSHDock.xcodeproj
```

在 Xcode 中选择 SSHDock scheme，`Cmd+R` 运行。

### 权限说明

首次启动时 macOS 会请求「自动化」权限以控制 Terminal / iTerm 执行 SSH 命令，请点击允许。可在 **系统设置 → 隐私与安全性 → 自动化** 中管理。

## 📝 使用说明

1. **新建连接**：点击左上角 `+` 或 `⌘N`，填写主机等信息
2. **启动连接**：双击列表项，或选中后点右上角「▶ 连接」(`⌘R`)
3. **收藏**：点击右侧详情页星标，或行内右键菜单
4. **菜单栏快速启动**：点击状态栏 🖥 图标，直接选择收藏的连接

## 🔒 安全说明

- 私钥**只保存路径**，不保存内容
- 密码保存在本地 SwiftData 数据库（`~/Library/Application Support/...`），**未加密**
- 仅建议在个人设备上保存密码；生产环境请用 SSH Key

## 📄 License

MIT
