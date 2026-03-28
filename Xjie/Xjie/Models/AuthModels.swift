import Foundation

// MARK: - 认证相关

struct AuthResponse: Codable {
    let access_token: String
    let refresh_token: String?
}

struct SubjectItem: Codable, Identifiable {
    var id: String { subject_id }
    let subject_id: String
    let cohort: String?
}

struct LoginSubjectBody: Encodable {
    let subject_id: String
}

struct LoginEmailBody: Encodable {
    let email: String
    let password: String
}

struct WxLoginBody: Encodable {
    let code: String
}
