// UIComponents.swift
// SSHDock
//
// 通用 UI 组件：服务器头像、标签 Chip、Toast 等

import SwiftUI

// MARK: - 根据字符串生成稳定颜色（用于服务器头像）

extension Color {
    static func deterministic(from string: String) -> Color {
        let palette: [Color] = [
            .blue, .purple, .pink, .orange, .green,
            .teal, .indigo, .red, .cyan, .mint, .brown
        ]
        let hash = abs(string.hashValue)
        return palette[hash % palette.count]
    }
}

// MARK: - 服务器头像

struct ServerAvatar: View {
    let name: String
    let host: String
    var size: CGFloat = 32
    var isFavorite: Bool = false

    private var initials: String {
        let source = name.isEmpty ? host : name
        let trimmed = source.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return "?" }
        // 取首字母 / 前两个首字母
        let words = trimmed.split(separator: " ").prefix(2)
        if words.count >= 2 {
            return words.map { String($0.prefix(1)) }.joined().uppercased()
        }
        return String(trimmed.prefix(1)).uppercased()
    }

    private var bgColor: Color {
        Color.deterministic(from: host.isEmpty ? name : host)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ZStack {
                RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [bgColor.opacity(0.9), bgColor.opacity(0.65)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text(initials)
                    .font(.system(size: size * 0.42, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
            }
            .frame(width: size, height: size)
            .shadow(color: bgColor.opacity(0.25), radius: 3, x: 0, y: 1)

            if isFavorite {
                Image(systemName: "star.fill")
                    .font(.system(size: size * 0.32))
                    .foregroundColor(.yellow)
                    .background(
                        Circle().fill(Color(nsColor: .windowBackgroundColor))
                            .frame(width: size * 0.42, height: size * 0.42)
                    )
                    .offset(x: size * 0.12, y: -size * 0.12)
            }
        }
    }
}

// MARK: - 标签 Chip

struct TagChip: View {
    let text: String
    var color: Color = .accentColor

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .medium))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule().fill(color.opacity(0.15))
            )
            .foregroundColor(color)
    }
}

// MARK: - Toast

struct Toast: View {
    let icon: String
    let text: String
    var color: Color = .green

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(text)
                .font(.callout)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.18), radius: 12, y: 4)
        )
    }
}

// MARK: - 卡片容器

struct CardSection<Content: View>: View {
    let title: String?
    let icon: String?
    @ViewBuilder var content: () -> Content

    init(_ title: String? = nil, icon: String? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let title = title {
                HStack(spacing: 6) {
                    if let icon = icon {
                        Image(systemName: icon)
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    Text(title)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                }
                .padding(.horizontal, 4)
            }
            VStack(spacing: 0) {
                content()
            }
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.secondary.opacity(0.15), lineWidth: 0.5)
            )
        }
    }
}

// MARK: - 表单行（统一视觉）

struct FormRow<Trailing: View>: View {
    let label: String
    var required: Bool = false
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 2) {
                Text(label)
                if required {
                    Text("*").foregroundColor(.red)
                }
            }
            .font(.callout)
            .foregroundColor(.primary)
            .frame(width: 90, alignment: .leading)

            trailing()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .overlay(
            Divider(), alignment: .bottom
        )
    }
}

// 去掉末尾 Divider 的修饰符
struct LastRowModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.overlay(Color.clear, alignment: .bottom)
    }
}
