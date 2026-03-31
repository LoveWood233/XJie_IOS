import Foundation

@MainActor
final class HealthBriefViewModel: ObservableObject {
    @Published var loading = false
    @Published var briefing: TodayBriefing?
    @Published var reports: HealthReports?
    @Published var aiSummary = ""
    @Published var summaryLoading = false
    @Published var summaryProgress: Double = 0
    @Published var summaryStage: String = ""
    @Published var errorMessage: String?

    private let api: APIServiceProtocol

    init(api: APIServiceProtocol = APIService.shared) {
        self.api = api
    }

    func fetchData() async {
        loading = true
        defer { loading = false }
        async let b: TodayBriefing? = try? await api.get("/api/agent/today")
        async let r: HealthReports? = try? await api.get("/api/health-reports")
        async let s: HealthDataSummary? = try? await api.get("/api/health-data/summary")
        let fetchedBriefing = await b
        let fetchedReports = await r
        let fetchedSummary = await s
        guard !Task.isCancelled else { return }
        briefing = fetchedBriefing
        reports = fetchedReports
        if let text = fetchedSummary?.summary_text, !text.isEmpty {
            aiSummary = text
        }
    }

    func loadAISummary() async {
        summaryLoading = true
        summaryProgress = 0
        summaryStage = "提交任务..."
        defer { summaryLoading = false; summaryStage = "" }

        do {
            // 1. Submit async task
            let task: SummaryTaskResponse = try await api.post("/api/health-data/summary/generate-async")
            let taskId = task.task_id

            // 2. Poll every 3 seconds
            while !Task.isCancelled {
                try await Task.sleep(for: .seconds(3))
                guard !Task.isCancelled else { return }

                let status: SummaryTaskResponse = try await api.get("/api/health-data/summary/task/\(taskId)")

                summaryProgress = status.progress_pct ?? 0

                switch status.stage {
                case "l1":
                    summaryStage = "分析第 \(status.stage_current ?? 0)/\(status.stage_total ?? 0) 次检查..."
                case "l2":
                    summaryStage = "汇总第 \(status.stage_current ?? 0)/\(status.stage_total ?? 0) 年趋势..."
                case "l3":
                    summaryStage = "生成最终报告..."
                default:
                    summaryStage = "准备中..."
                }

                if status.status == "done" {
                    // Fetch the final summary
                    let result: HealthDataSummary = try await api.get("/api/health-data/summary")
                    guard !Task.isCancelled else { return }
                    aiSummary = result.summary_text ?? "暂无摘要"
                    summaryProgress = 1.0
                    return
                }

                if status.status == "failed" {
                    aiSummary = "生成失败: \(status.error_message ?? "未知错误")"
                    return
                }
            }
        } catch {
            guard !Task.isCancelled else { return }
            aiSummary = "获取失败，请重试"
            errorMessage = error.localizedDescription
        }
    }
}
