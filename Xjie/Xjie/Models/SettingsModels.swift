import Foundation

// MARK: - 设置

struct UserSettings: Decodable {
    let intervention_level: String?
    let daily_reminder_limit: Int?
}

struct UpdateSettingsBody: Encodable {
    let intervention_level: String?
}

struct UpdateConsentBody: Encodable {
    let allow_ai_chat: Bool?
    let allow_data_upload: Bool?
}
