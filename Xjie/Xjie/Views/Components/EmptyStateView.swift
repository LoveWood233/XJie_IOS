import SwiftUI

/// 通用空状态组件 — 列表/卡片无数据时展示
struct EmptyStateView: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    var actionLabel: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(.appMuted)

            Text(title)
                .font(.headline)
                .foregroundColor(.appMuted)

            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.appMuted)
                    .multilineTextAlignment(.center)
            }

            if let actionLabel, let action {
                Button(action: action) {
                    Text(actionLabel)
                        .font(.subheadline.bold())
                        .foregroundColor(.appPrimary)
                }
                .padding(.top, 4)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}
