import SwiftUI

/// CODE-01: 共享文档标签组件 — 从 ExamReportViews / MedicalRecordViews 提取

/// 来源类型标签 (拍照 / CSV / PDF)
struct SourceTag: View {
    let sourceType: String?

    var body: some View {
        Text(sourceType == "photo" ? "拍照" : sourceType == "csv" ? "CSV" : "PDF")
            .font(.caption2)
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(Color.appMuted.opacity(0.1))
            .cornerRadius(4)
            .foregroundColor(.appMuted)
    }
}

/// 详情来源标签 (拍照上传 / CSV上传 / PDF上传)
struct SourceDetailTag: View {
    let sourceType: String?

    var body: some View {
        Text(sourceType == "photo" ? "拍照上传" : sourceType == "csv" ? "CSV上传" : "PDF上传")
            .font(.caption)
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(Color.appMuted.opacity(0.1))
            .cornerRadius(4)
    }
}

/// 提取状态标签 (已提取 / 处理中)
struct StatusTag: View {
    let status: String?

    var body: some View {
        Text(status == "done" ? "已提取" : "处理中")
            .font(.caption2)
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(status == "done" ? Color.appSuccess.opacity(0.1) : Color.appWarning.opacity(0.1))
            .foregroundColor(status == "done" ? .appSuccess : .appWarning)
            .cornerRadius(4)
    }
}

/// 详情状态标签（caption 字体）
struct StatusDetailTag: View {
    let status: String?

    var body: some View {
        Text(status == "done" ? "已提取" : "处理中")
            .font(.caption)
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(status == "done" ? Color.appSuccess.opacity(0.1) : Color.appWarning.opacity(0.1))
            .foregroundColor(status == "done" ? .appSuccess : .appWarning)
            .cornerRadius(4)
    }
}
