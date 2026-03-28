import SwiftUI

/// CODE-01: 共享指标卡片组件 — 从 HomeView / GlucoseView 提取
struct MetricItemView: View {
    let value: String
    let label: String
    var color: Color = .appText

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title3).bold()
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(.appMuted)
        }
    }
}
