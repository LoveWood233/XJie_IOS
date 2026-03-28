import Foundation

// MARK: - 膳食

struct MealItem: Codable, Identifiable {
    let id: String?
    let meal_ts: String?
    let meal_ts_source: String?
    let kcal: Double?
    let tags: [String]?
    let notes: String?
}

struct MealPhoto: Decodable, Identifiable {
    let id: String?
    let status: String?
    let calorie_estimate_kcal: Double?
    let confidence: Double?
    let uploaded_at: String?
}

struct MealUploadTicket: Decodable {
    let upload_url: String?
    let object_key: String?
}

struct MealCreateBody: Encodable {
    let meal_ts: String
    let meal_ts_source: String
    let kcal: Int
    let tags: [String]
    let notes: String
}

struct PhotoUploadBody: Encodable {
    let filename: String
    let content_type: String
}

struct PhotoCompleteBody: Encodable {
    let object_key: String
}
