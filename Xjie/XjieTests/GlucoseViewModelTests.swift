import XCTest
@testable import Xjie

/// GlucoseViewModel 单元测试
@MainActor
final class GlucoseViewModelTests: XCTestCase {

    func testFetchRangeSuccess() async throws {
        let mock = MockAPIService()
        let range = GlucoseRange(min_ts: "2024-01-01T00:00:00Z", max_ts: "2024-06-01T00:00:00Z")
        try await mock.setResponse(for: "/api/glucose/range", value: range)

        // fetchRange 会内部调用 fetchPoints，需要提供空数组
        let emptyPoints: [GlucosePoint] = []
        try await mock.setResult(emptyPoints) // fallback for all other paths

        let vm = GlucoseViewModel(api: mock)
        await vm.fetchRange()

        XCTAssertNotNil(vm.range)
        XCTAssertEqual(vm.range?.min_ts, "2024-01-01T00:00:00Z")
        XCTAssertFalse(vm.loading)
    }

    func testFetchPointsError() async {
        let mock = MockAPIService()
        await mock.setError(URLError(.timedOut))

        let vm = GlucoseViewModel(api: mock)
        await vm.fetchRange()

        XCTAssertNotNil(vm.errorMessage)
        XCTAssertTrue(vm.points.isEmpty)
        XCTAssertFalse(vm.loading)
    }

    func testWindowChange() async throws {
        let mock = MockAPIService()
        let emptyPoints: [GlucosePoint] = []
        try await mock.setResult(emptyPoints)

        let vm = GlucoseViewModel(api: mock)
        vm.window = "7d"
        await vm.fetchPoints()

        // 验证请求路径包含正确的查询参数
        let paths = await mock.requestedPaths
        let glucosePath = paths.first { $0.hasPrefix("/api/glucose?") }
        XCTAssertNotNil(glucosePath, "应请求 /api/glucose 带查询参数")
        XCTAssertTrue(glucosePath?.contains("from=") == true)
        XCTAssertTrue(glucosePath?.contains("limit=2000") == true)
    }
}
