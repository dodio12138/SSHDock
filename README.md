# SSHDock 开发预备文档

## 1. 项目概述

### 1.1 项目名称
**SSHDock**

### 1.2 一句话定义
SSHDock 是一个面向 macOS 的 SSH 登录入口管理工具，用于保存、命名、备注、分类和快速启动 SSH 连接，并在用户自己的终端中直接打开连接。

### 1.3 产品定位
SSHDock **不是终端模拟器**，也**不是完整的 SSH 客户端**。  
它的核心职责是：

- 管理用户常用 SSH 连接入口
- 提供清晰的命名、备注、标签和分组能力
- 以专业界面展示连接信息
- 在轻量模式下以菜单栏形式快速访问
- 在真正连接时，调用用户自己的 Terminal 或 iTerm 打开 SSH 会话

### 1.4 目标用户
- 开发者
- 运维工程师
- 机器人 / 嵌入式开发者
- 使用 AWS / VPS / 树莓派 / Jetson / Linux 服务器的个人或小团队
- 需要管理大量 SSH 登录信息，但不想频繁手写 `~/.ssh/config` 的用户

---

## 2. 产品目标

### 2.1 主要目标
构建一个原生 macOS 工具，使用户能够：

1. 方便地保存 SSH 登录信息
2. 用人类可读的名字管理服务器
3. 为连接添加备注、标签、分组
4. 快速搜索和启动连接
5. 在菜单栏中轻量使用
6. 在完整窗口中专业管理

### 2.2 非目标
以下内容**不属于第一阶段目标**：

- 自带终端模拟器
- SSH 协议栈自实现
- 内嵌 shell 会话
- SFTP 文件浏览器
- 多设备云同步
- 团队协作共享
- 实时监控平台
- 自动运维功能

---

## 3. 核心理念

SSHDock 的设计理念：

- **管理入口，而不是替代终端**
- **专业但轻量**
- **原生 macOS 风格**
- **高频连接更快，低频管理更清晰**
- **把 SSH 主机当作“书签”管理**

---

## 4. 使用场景

### 4.1 典型场景
#### 场景 A：开发者管理多台云服务器
用户维护多个 AWS / VPS 主机，希望通过清晰名称快速连接，而不是记忆 IP 和私钥路径。

#### 场景 B：机器人 / 实验设备管理
用户有多台树莓派、Jetson、工控机，需要通过备注区分用途，例如：
- Lab-Robot-01
- Orin-Perception
- Pi-Greenhouse
- Remote-Logger

#### 场景 C：菜单栏快速启动
用户平时不想打开完整 App，只想点击菜单栏图标，搜索一个连接并打开终端。

#### 场景 D：集中整理 SSH 条目
用户希望给连接添加：
- 名称
- 备注
- 分组
- 标签
- 收藏
- 最近连接记录

---

## 5. 产品形态

SSHDock 采用双模式设计：

### 5.1 专业模式（Main Window）
用于集中管理连接信息，适合：
- 创建和编辑条目
- 分类整理
- 搜索和筛选
- 查看备注与连接详情
- 批量维护 SSH 入口

### 5.2 轻量模式（Menu Bar）
用于高频快速连接，适合：
- 打开菜单栏弹窗
- 搜索连接
- 查看最近连接
- 点击后直接在终端中打开 SSH 会话

---

## 6. 第一阶段产品范围（MVP）

### 6.1 必须实现的功能
#### 连接条目管理
- 新建 SSH 连接条目
- 编辑 SSH 连接条目
- 删除 SSH 连接条目
- 收藏 / 取消收藏
- 查看最近连接

#### 连接信息字段
- 显示名称
- Host / IP
- 用户名
- 端口
- 私钥路径（可选）
- 备注（可选）
- 分组（可选）
- 标签（可选）
- 默认终端类型（Terminal / iTerm，可选）

#### 启动功能
- 在 Terminal 中打开连接
- 在 iTerm 中打开连接
- 复制 SSH 命令
- 从菜单栏直接启动连接

#### 界面能力
- 主窗口三栏布局
- 菜单栏弹窗
- 搜索连接
- 收藏列表
- 最近连接列表
- 深色模式支持

#### 数据存储
- 本地持久化保存连接数据
- 不依赖云端
- 不修改系统 SSH 配置

---

## 7. 后续阶段可扩展功能

### 7.1 第二阶段建议功能
- 导入 `~/.ssh/config`
- 导出连接配置
- 状态检测（Ping / TCP Reachability）
- 自定义标签颜色
- 自定义全局快捷键
- 启动时选择默认终端
- 常用命令模板
- 支持 ProxyJump / Bastion 参数
- 拖拽调整分组顺序

### 7.2 第三阶段建议功能
- 与系统 SSH 配置同步
- 跳板机可视化配置
- 命令片段收藏
- 主机图标与状态面板
- 团队共享配置
- 云同步
- 插件系统

---

## 8. 非功能需求

### 8.1 性能
- App 启动快速
- 菜单栏弹窗打开快速
- 搜索响应即时
- 数据量在 100~1000 个 SSH 条目时仍保持流畅

### 8.2 可用性
- 新建连接流程简单
- 常用操作不超过 2~3 步
- 不要求用户理解 SSH 配置语法
- 界面信息层级清晰

### 8.3 可靠性
- 数据不能轻易丢失
- 启动命令生成必须可预测
- 不因异常写入而破坏用户数据

### 8.4 安全性
- 不明文保存敏感口令
- 私钥文件只保存路径引用
- 后续可接入 macOS Keychain
- 尽量依赖系统现有 SSH 能力

---

## 9. 技术路线建议

### 9.1 推荐技术栈
#### 首选方案
- **语言**：Swift
- **UI**：SwiftUI
- **系统集成**：AppKit（补充菜单栏、窗口行为、系统交互）
- **数据层**：SwiftData / Core Data / 本地 JSON / SQLite（择一）
- **系统自动化**：AppleScript / NSWorkspace / Process 方式打开 Terminal 或 iTerm

### 9.2 推荐原因
选择 SwiftUI + AppKit 的理由：

- 更符合 macOS 原生体验
- 菜单栏应用支持自然
- 深浅色适配方便
- 窗口与弹窗交互更成熟
- 后续集成 Keychain 更直接
- 资源占用更低
- 更容易做出“专业但轻量”的产品质感

### 9.3 不建议的首版路线
#### Electron
可以做，但：
- 资源占用相对更高
- 菜单栏与原生体验通常稍弱
- 系统终端联动细节处理较繁琐

#### Tauri
可行，但首版目标是高质量 macOS 原生体验时，SwiftUI 更合适

---

## 10. 终端联动方案

### 10.1 核心原则
SSHDock 本身不承载终端会话，只负责拼接和触发 SSH 命令。

### 10.2 目标终端
首版支持：
- macOS Terminal
- iTerm2

### 10.3 启动流程
用户点击某个 SSH 条目后：

1. 读取本地配置
2. 生成 SSH 命令
3. 按用户配置选择 Terminal 或 iTerm
4. 通过系统接口打开终端
5. 将命令发送给终端执行

### 10.4 基础命令格式
无私钥时：

```bash
ssh username@host -p 22
```

有私钥时：

```bash
ssh -i ~/.ssh/key.pem username@host -p 22
```

### 10.5 后续可扩展参数
- `-J` ProxyJump
- `-L` / `-R` 端口转发
- 自定义额外参数
- 指定 shell 初始化命令

---

## 11. 数据模型设计

### 11.1 HostEntry
```ts
type HostEntry = {
  id: string
  name: string
  host: string
  username: string
  port: number
  identityFile?: string
  note?: string
  groupId?: string
  tagIds?: string[]
  isFavorite: boolean
  preferredTerminal?: "terminal" | "iterm" | "systemDefault"
  lastConnectedAt?: string
  createdAt: string
  updatedAt: string
}
```

### 11.2 Group
```ts
type Group = {
  id: string
  name: string
  order: number
  createdAt: string
  updatedAt: string
}
```

### 11.3 Tag
```ts
type Tag = {
  id: string
  name: string
  color?: string
  createdAt: string
  updatedAt: string
}
```

### 11.4 AppSettings
```ts
type AppSettings = {
  launchAtLogin: boolean
  defaultTerminal: "terminal" | "iterm"
  closeToMenuBar: boolean
  showInDock: boolean
  globalShortcutEnabled: boolean
  themeMode: "system" | "light" | "dark"
}
```

### 11.5 Recent Connection
也可以不单独建表，直接使用 `lastConnectedAt` 排序生成最近列表。  
如果后续需要记录详细历史，可扩展：

```ts
type ConnectionHistory = {
  id: string
  hostEntryId: string
  connectedAt: string
  terminal: "terminal" | "iterm"
}
```

---

## 12. 存储方案建议

### 12.1 第一阶段建议
采用**本地数据库或本地结构化存储**，优先考虑：

#### 方案 A：SwiftData
优点：
- 和 SwiftUI 集成自然
- 开发效率高
- 适合原生应用首版快速迭代

#### 方案 B：SQLite
优点：
- 可控性高
- 数据迁移更成熟
- 后续扩展空间大

#### 方案 C：JSON 文件
优点：
- 最简单
- 适合极早期原型

缺点：
- 后续数据迁移和复杂查询会变麻烦

### 12.2 建议结论
- 原型：JSON 或 SwiftData
- 正式第一版：SwiftData 或 SQLite

---

## 13. 安全策略

### 13.1 不保存的内容
首版不建议保存：
- SSH 密码明文
- 私钥文件内容
- 用户 shell 凭证

### 13.2 保存的内容
可保存：
- 私钥路径
- Host / 用户名 / 端口
- 备注、标签、分组
- 用户偏好设置

### 13.3 后续增强
- 集成 macOS Keychain
- 对敏感字段进行受保护存储
- 支持 Touch ID 解锁敏感配置

---

## 14. 与 `~/.ssh/config` 的关系

### 14.1 第一阶段策略
**不直接读写系统 `~/.ssh/config`**  
SSHDock 维护自己的连接配置库。

### 14.2 原因
- 减少误改用户现有 SSH 配置的风险
- 降低解析与写回复杂度
- 减少兼容问题
- 更容易做稳定的首版体验

### 14.3 第二阶段扩展
- 支持导入系统 SSH config
- 支持导出为 SSH config 片段
- 支持从指定 Host alias 创建条目

---

## 15. 信息架构设计

### 15.1 主窗口结构
建议采用三栏布局：

#### 左栏：导航区
- All Connections
- Favorites
- Recent
- Groups
- Tags
- Settings

#### 中栏：连接列表区
每个条目显示：
- 名称
- Host / IP
- 用户名
- 分组 / 标签
- 最近连接时间
- 收藏状态

#### 右栏：详情区
显示：
- 基本连接信息
- 备注
- 终端偏好
- SSH 命令预览
- 操作按钮
  - Connect
  - Copy Command
  - Edit
  - Delete

### 15.2 菜单栏弹窗结构
建议布局：

#### 顶部
- 搜索框

#### 中部
- Favorites
- Recent
- All Connections（最多显示若干项）

#### 底部
- New Connection
- Open SSHDock
- Settings
- Quit

---

## 16. 关键交互流程

### 16.1 新建连接
1. 点击 New Connection
2. 填写名称、Host、用户名、端口
3. 可选填写私钥路径、备注、分组、标签
4. 保存
5. 在列表中展示

### 16.2 快速连接
1. 点击某个连接
2. 生成 SSH 命令
3. 通过 Terminal / iTerm 启动
4. 记录最近连接时间

### 16.3 菜单栏快速连接
1. 点击菜单栏图标
2. 输入连接名称关键词
3. 回车启动
4. 自动打开终端

### 16.4 编辑连接
1. 在列表中选中条目
2. 打开详情或编辑页
3. 修改字段
4. 保存更新

---

## 17. UI / UX 设计建议

### 17.1 视觉风格关键词
- 原生
- 简洁
- 专业
- 开发者工具感
- 不花哨
- 有信息密度，但不拥挤

### 17.2 参考风格
- Raycast
- Linear
- Notion macOS 客户端
- Warp 的部分布局风格
- Apple 自带设置类界面

### 17.3 重点体验原则
- 搜索优先
- 连接按钮清晰
- 新建和编辑表单简洁
- 信息展示层级明确
- 菜单栏弹窗不能臃肿
- 不把用户强行锁在你的工作流中

---

## 18. 开发阶段规划

### 18.1 Phase 0：原型验证
目标：
- 验证基础数据结构
- 验证打开 Terminal / iTerm 的技术链路
- 验证菜单栏弹窗体验

交付：
- 可以添加一个 SSH 条目
- 可以点击后打开终端
- 可以从菜单栏启动连接

### 18.2 Phase 1：MVP
目标：
- 完整连接管理
- 主窗口三栏
- 菜单栏搜索与启动
- 收藏 / 最近连接
- 本地持久化

交付：
- 可日常使用的首版 SSHDock

### 18.3 Phase 2：增强版
目标：
- 导入 SSH Config
- 状态检测
- 设置页
- 快捷键
- 更完善的列表筛选和标签

### 18.4 Phase 3：专业版
目标：
- 跳板机支持
- 高级连接参数
- 团队共享或同步能力
- 更强的数据导入导出

---

## 19. 技术风险与应对

### 19.1 风险：Terminal / iTerm 自动化不一致
问题：
- 不同终端的脚本接口不同
- 用户环境配置存在差异

应对：
- 先做好 Terminal 支持
- iTerm 作为增强支持
- 命令生成和终端调用逻辑解耦

### 19.2 风险：命令拼接错误
问题：
- 路径包含空格
- 字段为空
- 参数顺序不合理

应对：
- 统一命令生成器
- 对字段做严格校验
- 对路径和参数做转义处理

### 19.3 风险：范围膨胀
问题：
- 很容易把项目做成“全功能远程管理平台”

应对：
- 明确首版只做 SSH 入口管理
- 禁止首版引入内嵌终端
- 每个阶段都限制功能边界

### 19.4 风险：数据迁移
问题：
- 早期字段设计变化频繁
- 本地数据格式升级可能出错

应对：
- 尽早确定核心数据模型
- 引入版本号
- 预留迁移逻辑

---

## 20. 建议开发顺序

### Step 1：数据模型
先完成：
- HostEntry
- Group
- Tag
- AppSettings

### Step 2：命令生成器
完成：
- SSH 命令组装
- 参数校验
- 路径转义

### Step 3：终端调用
完成：
- Terminal 打开并执行命令
- iTerm 打开并执行命令

### Step 4：主窗口 UI
完成：
- 左侧导航
- 中间列表
- 右侧详情
- 新建 / 编辑表单

### Step 5：菜单栏
完成：
- 状态栏图标
- 搜索框
- 最近 / 收藏列表
- 快速启动

### Step 6：持久化与设置
完成：
- 本地存储
- 默认终端设置
- 关闭到菜单栏
- 开机启动

---

## 21. 首版验收标准

当满足以下条件时，可认为 SSHDock MVP 完成：

- 可以创建、编辑、删除 SSH 连接条目
- 可以通过名称搜索条目
- 可以收藏和查看最近连接
- 可以从主窗口启动连接
- 可以从菜单栏启动连接
- 可以在 Terminal 中成功打开 SSH
- 可以在 iTerm 中成功打开 SSH
- 本地数据可稳定持久化
- 深色模式下界面可正常使用
- 应用关闭后仍可通过菜单栏驻留

---

## 22. 推荐目录结构（Swift 项目草案）

```text
SSHDock/
├── App/
│   ├── SSHDockApp.swift
│   ├── AppDelegate.swift
│   └── AppState.swift
├── Models/
│   ├── HostEntry.swift
│   ├── Group.swift
│   ├── Tag.swift
│   └── AppSettings.swift
├── Services/
│   ├── SSHCommandBuilder.swift
│   ├── TerminalLauncher.swift
│   ├── ItermLauncher.swift
│   ├── StorageService.swift
│   └── SettingsService.swift
├── Views/
│   ├── MainWindow/
│   ├── MenuBar/
│   ├── HostEditor/
│   └── Settings/
├── ViewModels/
│   ├── HostListViewModel.swift
│   ├── HostDetailViewModel.swift
│   └── MenuBarViewModel.swift
├── Resources/
└── Utilities/
```

---

## 23. 产品文案草案

### 23.1 产品介绍
**SSHDock** 是一个专为 macOS 设计的 SSH 登录入口管理工具。  
它帮助用户保存、组织和快速打开 SSH 连接，在保留专业管理界面的同时，也支持以菜单栏形式轻量使用。

### 23.2 宣传语候选
- Your SSH connections, neatly docked.
- Organize SSH like bookmarks.
- A native macOS launcher for SSH connections.
- Professional when managing, instant when connecting.

### 23.3 中文宣传语候选
- 把你的 SSH 连接整齐停靠起来
- 像管理书签一样管理 SSH
- 专业管理，快速连接
- 属于 macOS 的 SSH 入口工具

---

## 24. 下一步建议

在正式编码前，建议继续完成以下产物：

1. 低保真线框图
2. 数据字段最终确认表
3. Terminal / iTerm 调用验证 Demo
4. 菜单栏交互原型
5. MVP 开发排期

---

## 25. 结论

SSHDock 是一个边界清晰、开发可控、需求真实的 macOS 工具项目。  
其核心价值不在于替代终端，而在于让 SSH 登录入口的组织、命名、备注和启动过程更自然、更高效、更符合 macOS 用户习惯。

首版应坚持以下原则：

- 只做 SSH 入口管理
- 直接调用用户现有终端
- 重视菜单栏轻量体验
- 保持原生与专业感
- 避免功能膨胀

如果以上原则执行到位，SSHDock 非常适合作为一个可落地、可持续迭代的独立 macOS 产品。
# SSHDock
