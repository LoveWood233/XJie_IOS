import Foundation

@MainActor
final class LoginViewModel: ObservableObject {
    enum LoginMode { case subject, email }

    @Published var mode: LoginMode = .subject
    @Published var subjects: [SubjectItem] = []
    @Published var loading = false
    @Published var selectedSubject = ""
    @Published var email = ""
    @Published var password = ""
    @Published var isSignup = false
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var errorMessage: String?

    private let api: APIServiceProtocol

    init(api: APIServiceProtocol = APIService.shared) {
        self.api = api
    }

    func loadSubjects() async {
        do {
            subjects = try await api.get("/api/auth/subjects")
        } catch {
            // 后端未启动时静默处理，不弹窗
            errorMessage = error.localizedDescription
        }
    }

    func loginSubject(authManager: AuthManager) async {
        guard !selectedSubject.isEmpty else {
            alertMessage = "请选择受试者"; showAlert = true; return
        }
        loading = true
        defer { loading = false }
        do {
            let res: AuthResponse = try await api.post(
                "/api/auth/login-subject",
                body: LoginSubjectBody(subject_id: selectedSubject)
            )
            authManager.setAuth(accessToken: res.access_token, refreshToken: res.refresh_token ?? "")
            authManager.setSubject(selectedSubject)
        } catch {
            alertMessage = error.localizedDescription; showAlert = true
        }
    }

    func loginEmail(authManager: AuthManager) async {
        guard !email.isEmpty, !password.isEmpty else {
            alertMessage = "请填写邮箱和密码"; showAlert = true; return
        }
        guard password.count >= 8 else {
            alertMessage = "密码至少 8 位"; showAlert = true; return
        }
        loading = true
        defer { loading = false }
        do {
            let path = isSignup ? "/api/auth/signup" : "/api/auth/login"
            let res: AuthResponse = try await api.post(
                path, body: LoginEmailBody(email: email, password: password)
            )
            authManager.setAuth(accessToken: res.access_token, refreshToken: res.refresh_token ?? "")
        } catch {
            alertMessage = error.localizedDescription; showAlert = true
        }
    }
}
