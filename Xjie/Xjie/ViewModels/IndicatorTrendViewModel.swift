import Foundation

@MainActor
final class IndicatorTrendViewModel: ObservableObject {
    @Published var allIndicators: [IndicatorInfo] = []
    @Published var watchedNames: [String] = []
    @Published var trends: [IndicatorTrend] = []
    @Published var explanations: [String: IndicatorExplanation] = [:]
    @Published var loading = false
    @Published var trendLoading = false
    @Published var errorMessage: String?

    private let api: APIServiceProtocol

    init(api: APIServiceProtocol = APIService.shared) {
        self.api = api
    }

    // MARK: - Load available indicators

    func fetchIndicators() async {
        loading = true
        defer { loading = false }
        do {
            async let indicatorsReq: IndicatorListResponse = api.get("/api/health-data/indicators")
            async let watchedReq: WatchedListResponse = api.get("/api/health-data/indicators/watched")
            let indicators = try await indicatorsReq
            let watched = try await watchedReq
            guard !Task.isCancelled else { return }
            allIndicators = indicators.indicators
            watchedNames = watched.items.map(\.indicator_name)

            // Auto-load trends for watched indicators
            if !watchedNames.isEmpty {
                await fetchTrends(for: watchedNames)
            }
        } catch {
            guard !Task.isCancelled else { return }
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Load trend data

    func fetchTrends(for names: [String]) async {
        guard !names.isEmpty else {
            trends = []
            return
        }
        trendLoading = true
        defer { trendLoading = false }
        do {
            let joined = names.joined(separator: ",")
            let encoded = joined.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? joined
            let resp: IndicatorTrendResponse = try await api.get("/api/health-data/indicators/trend?names=\(encoded)")
            guard !Task.isCancelled else { return }
            trends = resp.indicators
        } catch {
            guard !Task.isCancelled else { return }
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Watch / Unwatch

    func watch(_ name: String, category: String? = nil) async {
        do {
            let body = ["indicator_name": name, "category": category ?? ""]
            let _: [String: String] = try await api.post("/api/health-data/indicators/watch", body: body)
            guard !Task.isCancelled else { return }
            if !watchedNames.contains(name) {
                watchedNames.append(name)
            }
            await fetchTrends(for: watchedNames)
        } catch {
            guard !Task.isCancelled else { return }
            errorMessage = error.localizedDescription
        }
    }

    func unwatch(_ name: String) async {
        do {
            let encoded = name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? name
            let _: [String: Bool] = try await api.delete("/api/health-data/indicators/watch/\(encoded)")
            guard !Task.isCancelled else { return }
            watchedNames.removeAll { $0 == name }
            trends.removeAll { $0.name == name }
        } catch {
            guard !Task.isCancelled else { return }
            errorMessage = error.localizedDescription
        }
    }

    /// 批量应用选择：对比 pending 与当前 watched，增删差异后刷新趋势
    func applySelection(_ selected: Set<String>) async {
        let current = Set(watchedNames)
        let toAdd = selected.subtracting(current)
        let toRemove = current.subtracting(selected)

        for name in toRemove {
            await unwatch(name)
        }
        for name in toAdd {
            let category = allIndicators.first { $0.name == name }?.category
            await watchSilent(name, category: category)
        }

        watchedNames = Array(selected)
        if !watchedNames.isEmpty {
            await fetchTrends(for: watchedNames)
        } else {
            trends = []
        }
    }

    /// 静默 watch（不触发 fetchTrends，由 applySelection 统一刷新）
    private func watchSilent(_ name: String, category: String?) async {
        do {
            let body = ["indicator_name": name, "category": category ?? ""]
            let _: [String: String] = try await api.post("/api/health-data/indicators/watch", body: body)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// 获取指标解释（优先知识库缓存）
    func fetchExplanation(for name: String) async {
        guard explanations[name] == nil else { return }
        do {
            let encoded = name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? name
            let resp: IndicatorExplanation = try await api.get("/api/health-data/indicators/\(encoded)/explain")
            guard !Task.isCancelled else { return }
            explanations[name] = resp
        } catch {
            // Silently fail — explanation is optional
        }
    }
}
