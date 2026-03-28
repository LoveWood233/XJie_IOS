import XCTest
@testable import Xjie

/// LoginViewModel 单元测试
@MainActor
final class LoginViewModelTests: XCTestCase {

    // MARK: - Validation

    func testLoginSubjectEmptyShowsAlert() async {
        let mock = MockAPIService()
        let vm = LoginViewModel(api: mock)
        let auth = AuthManager.shared

        vm.selectedSubject = ""
        await vm.loginSubject(authManager: auth)

        XCTAssertTrue(vm.showAlert)
        XCTAssertEqual(vm.alertMessage, "请选择受试者")
    }

    func testLoginEmailEmptyShowsAlert() async {
        let mock = MockAPIService()
        let vm = LoginViewModel(api: mock)
        let auth = AuthManager.shared

        vm.email = ""
        vm.password = ""
        await vm.loginEmail(authManager: auth)

        XCTAssertTrue(vm.showAlert)
        XCTAssertEqual(vm.alertMessage, "请填写邮箱和密码")
    }

    func testLoginEmailShortPasswordShowsAlert() async {
        let mock = MockAPIService()
        let vm = LoginViewModel(api: mock)
        let auth = AuthManager.shared

        vm.email = "test@test.com"
        vm.password = "short"
        await vm.loginEmail(authManager: auth)

        XCTAssertTrue(vm.showAlert)
        XCTAssertEqual(vm.alertMessage, "密码至少 8 位")
    }

    // MARK: - Success

    func testLoginSubjectSuccess() async throws {
        let mock = MockAPIService()
        let response = AuthResponse(access_token: "tok_abc", refresh_token: "ref_xyz")
        try await mock.setResponse(for: "/api/auth/login-subject", value: response)

        let vm = LoginViewModel(api: mock)
        let auth = AuthManager.shared
        auth.logout() // 清理

        vm.selectedSubject = "SC001"
        await vm.loginSubject(authManager: auth)

        XCTAssertFalse(vm.showAlert, "不应弹窗")
        XCTAssertEqual(auth.token, "tok_abc")
        XCTAssertEqual(auth.subjectId, "SC001")
        XCTAssertFalse(vm.loading)

        auth.logout() // 清理
    }

    func testLoginEmailSuccess() async throws {
        let mock = MockAPIService()
        let response = AuthResponse(access_token: "tok_email", refresh_token: "ref_email")
        try await mock.setResponse(for: "/api/auth/login", value: response)

        let vm = LoginViewModel(api: mock)
        let auth = AuthManager.shared
        auth.logout()

        vm.email = "user@example.com"
        vm.password = "password123"
        await vm.loginEmail(authManager: auth)

        XCTAssertFalse(vm.showAlert)
        XCTAssertEqual(auth.token, "tok_email")
        XCTAssertFalse(vm.loading)

        auth.logout()
    }

    // MARK: - Error

    func testLoginSubjectNetworkError() async {
        let mock = MockAPIService()
        await mock.setError(URLError(.timedOut))

        let vm = LoginViewModel(api: mock)
        let auth = AuthManager.shared

        vm.selectedSubject = "SC001"
        await vm.loginSubject(authManager: auth)

        XCTAssertTrue(vm.showAlert)
        XCTAssertFalse(vm.alertMessage.isEmpty)
        XCTAssertFalse(vm.loading)
    }

    // MARK: - loadSubjects

    func testLoadSubjectsSuccess() async throws {
        let mock = MockAPIService()
        let subjects = [
            SubjectItem(subject_id: "SC001", cohort: "A"),
            SubjectItem(subject_id: "SC002", cohort: "B"),
        ]
        try await mock.setResult(subjects)

        let vm = LoginViewModel(api: mock)
        await vm.loadSubjects()

        XCTAssertEqual(vm.subjects.count, 2)
        XCTAssertEqual(vm.subjects[0].subject_id, "SC001")
    }

    func testLoadSubjectsError() async {
        let mock = MockAPIService()
        await mock.setError(URLError(.cannotConnectToHost))

        let vm = LoginViewModel(api: mock)
        await vm.loadSubjects()

        XCTAssertTrue(vm.subjects.isEmpty)
        XCTAssertNotNil(vm.errorMessage)
    }
}
