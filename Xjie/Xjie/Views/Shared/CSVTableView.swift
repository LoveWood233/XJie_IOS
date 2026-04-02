import SwiftUI

/// CODE-01: 共享 CSV 表格组件 — 从 ExamReportViews / MedicalRecordViews 提取
struct CSVTableView: View {
    let title: String
    let icon: String
    let columns: [String]
    let rows: [[String]]
    var highlightAbnormal: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon).font(.headline).foregroundColor(.appText)
            ScrollView(.horizontal) {
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        ForEach(columns, id: \.self) { col in
                            Text(col)
                                .font(.caption.bold())
                                .foregroundColor(.appText)
                                .frame(minWidth: 80).padding(6)
                                .background(Color.appPrimary.opacity(0.1))
                        }
                    }
                    ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                        let abnormal = highlightAbnormal && Self.isRowAbnormal(row)
                        HStack(spacing: 0) {
                            ForEach(Array(row.enumerated()), id: \.offset) { _, cell in
                                Text(cell)
                                    .font(.caption)
                                    .foregroundColor(abnormal ? .appDanger : .appText)
                                    .frame(minWidth: 80).padding(6)
                                    .background(abnormal ? Color.appDanger.opacity(0.05) : Color.clear)
                            }
                        }
                        Divider()
                    }
                }
            }
        }
        .cardStyle()
    }

    static func isRowAbnormal(_ row: [String]) -> Bool {
        guard let last = row.last else { return false }
        return last == "↑" || last == "↓" || last == "异常" || last.contains("偏")
    }
}
