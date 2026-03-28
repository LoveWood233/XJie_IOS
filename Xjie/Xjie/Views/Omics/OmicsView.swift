import SwiftUI

/// 多组学数据页面 — 对应小程序 pages/omics/omics
struct OmicsView: View {
    @State private var activeTab = 0

    private let tabs = ["蛋白组学", "代谢组学", "基因组学"]

    // TODO: CODE-03 — 以下占位数据待接入后端 API，当前为静态展示
    // 占位数据 (对应 omics.js 的 data)
    private let proteomics = OmicsPanel(
        title: "蛋白组学", icon: "allergens",
        desc: "通过质谱分析技术检测血液中的蛋白质表达谱，识别疾病相关的生物标志物。",
        items: [
            OmicsItem(name: "CRP (C-反应蛋白)", value: "--", unit: "mg/L"),
            OmicsItem(name: "TNF-α (肿瘤坏死因子)", value: "--", unit: "pg/mL"),
            OmicsItem(name: "IL-6 (白介素-6)", value: "--", unit: "pg/mL"),
            OmicsItem(name: "Adiponectin (脂联素)", value: "--", unit: "μg/mL"),
        ]
    )
    private let metabolomics = OmicsPanel(
        title: "代谢组学", icon: "flask",
        desc: "利用代谢物谱分析技术检测体内小分子代谢产物，反映机体代谢状态。",
        items: [
            OmicsItem(name: "BCAA (支链氨基酸)", value: "--", unit: "μmol/L"),
            OmicsItem(name: "TMAO (氧化三甲胺)", value: "--", unit: "μmol/L"),
            OmicsItem(name: "Bile Acids (胆汁酸)", value: "--", unit: "μmol/L"),
            OmicsItem(name: "Ceramides (神经酰胺)", value: "--", unit: "nmol/L"),
        ]
    )
    private let genomics = OmicsPanel(
        title: "基因组学", icon: "microscope",
        desc: "基于全基因组关联分析 (GWAS)，评估个体遗传风险和药物基因组学特征。",
        items: [
            OmicsItem(name: "TCF7L2 (2 型糖尿病风险)", value: "--", unit: ""),
            OmicsItem(name: "FTO (肥胖易感基因)", value: "--", unit: ""),
            OmicsItem(name: "APOE (脂代谢基因)", value: "--", unit: ""),
            OmicsItem(name: "MTHFR (叶酸代谢基因)", value: "--", unit: ""),
        ]
    )

    private var currentPanel: OmicsPanel {
        switch activeTab {
        case 0: return proteomics
        case 1: return metabolomics
        default: return genomics
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    // Tab 切换
                    tabBar

                    // 面板内容
                    panelView(currentPanel)

                    // 底部说明
                    Label("多组学数据需通过专业机构检测后上传，当前为占位展示。", systemImage: "info.circle")
                        .font(.caption)
                        .foregroundColor(.appMuted)
                        .padding()
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .background(Color.appBackground)
            .navigationTitle("多组学")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(Array(tabs.enumerated()), id: \.offset) { i, label in
                Button { activeTab = i } label: {
                    Text(label)
                        .font(.subheadline.bold())
                        .foregroundColor(activeTab == i ? .white : .appPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(activeTab == i ? Color.appPrimary : Color.clear)
                        .cornerRadius(8)
                }
            }
        }
        .padding(4)
        .background(Color.appPrimary.opacity(0.1))
        .cornerRadius(10)
    }

    private func panelView(_ panel: OmicsPanel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: panel.icon)
                    .font(.title2)
                    .foregroundColor(.appPrimary)
                Text(panel.title).font(.headline)
            }
            Text(panel.desc)
                .font(.subheadline)
                .foregroundColor(.appMuted)

            ForEach(panel.items) { item in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.name).font(.subheadline)
                        if !item.unit.isEmpty {
                            Text(item.unit).font(.caption).foregroundColor(.appMuted)
                        }
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text(item.value)
                            .font(.subheadline).bold()
                            .foregroundColor(.appMuted)
                        Text("待检测")
                            .font(.caption2)
                            .foregroundColor(.appMuted)
                    }
                }
                .padding(12)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(8)
            }
        }
        .cardStyle()
    }
}

// MARK: - 数据模型

struct OmicsPanel {
    let title: String
    let icon: String
    let desc: String
    let items: [OmicsItem]
}

struct OmicsItem: Identifiable {
    let id = UUID()
    let name: String
    let value: String
    let unit: String
}
