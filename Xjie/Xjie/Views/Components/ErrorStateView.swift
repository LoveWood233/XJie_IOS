import SwiftUI

/// 通用错误状态组件 — 网络错误、服务器错误、认证过期等
struct ErrorStateView: View {
    let message: String
    var retryAction: (() async -> Void)? = nil

    private var icon: String {
        if message.contains("网络") || message.contains("连接") {
            return "wifi.slash"
        } else if message.contains("认证") || message.contains("登录") || message.contains("token") {
            return "lock.trianglebadge.exclamationmark"
        } else {
            return "exclamationmark.icloud"
        }
    }

    private var title: String {
        if message.contains("网络") || message.contains("连接") {
            return "网络不可用"
        } else if message.contains("认证") || message.contains("登录") || message.contains("token") {
            return "认证过期"
        } else {
            return "加载失败"
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(.appDanger)

            Text(title)
                .font(.headline)
                .foregroundColor(.appText)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.appMuted)
                .multilineTextAlignment(.center)

            if let retryAction {
                Button {
                    Task { await retryAction() }
                } label: {
                    Label("重试", systemImage: "arrow.clockwise")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(Color.appPrimary)
                        .cornerRadius(8)
                }
                .padding(.top, 4)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}
