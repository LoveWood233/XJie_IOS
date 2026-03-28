import Foundation

@MainActor
final class HealthBriefViewModel: ObservableObject {
    @Published var loading = false
    @Published var briefing: TodayBriefing?
    @Published var reports: HealthReports?
    @Published var aiSummary = ""
    @Published var summaryLoading = false
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
        let fetchedBriefing = await b
        let fetchedReports = await r
        guard !Task.isCancelled else { return }
        briefing = fetchedBriefing
        reports = fetchedReports
    }

    func loadAISummary() async {
        summaryLoading = true
        defer { summaryLoading = false }
        do {
            // TODO: [LLM API] 后端调用 LLM 生成 AI 健康摘要
            // 如果 LLM 服务未部署，后端应返回预设文本或错误提示
            let res: AISummaryResponse = try await api.get("/api/health-reports/ai-summary-sync")
            guard !Task.isCancelled else { return }
            aiSummary = res.summary ?? "暂无摘要"
        } catch {
            guard !Task.isCancelled else { return }
            aiSummary = "获取失败，请重试"
            errorMessage = error.localizedDescription
        }
    }
}
