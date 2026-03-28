import Foundation

/// 首页 ViewModel — ARCH-02: 依赖注入 APIServiceProtocol
/// NET-03: 离线缓存支持
@MainActor
final class HomeViewModel: ObservableObject {
    @Published var loading = false
    @Published var dashboard: DashboardHealth?
    @Published var proactive: ProactiveMessage?
    @Published var errorMessage: String?
    @Published var isOfflineData = false

    private let api: APIServiceProtocol
    private let cache = OfflineCacheManager.shared
    private let dashboardCacheKey = "dashboard_health"

    init(api: APIServiceProtocol = APIService.shared) {
        self.api = api
    }

    func fetchData() async {
        loading = true
        defer { loading = false }
        do {
            let d: DashboardHealth = try await api.get("/api/dashboard/health")
            guard !Task.isCancelled else { return }
            dashboard = d
            isOfflineData = false
            cache.save(d, for: dashboardCacheKey)
        } catch {
            guard !Task.isCancelled else { return }
            // NET-03: 失败时加载离线缓存
            if let cached: DashboardHealth = cache.load(for: dashboardCacheKey) {
                dashboard = cached
                isOfflineData = true
            } else {
                errorMessage = error.localizedDescription
            }
        }
        guard !Task.isCancelled else { return }
        proactive = try? await api.get("/api/agent/proactive")
    }
}
