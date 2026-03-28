import Foundation

// MARK: - 聊天

struct ChatConversation: Codable, Identifiable {
    let id: String
    let title: String?
    let message_count: Int?
}

/// BUG-01 FIX: id 改为存储属性，避免 computed property 每次访问生成新 UUID
/// 导致 SwiftUI ForEach 无限刷新
struct ChatMessage: Decodable, Identifiable {
    let id: String
    let role: String
    let content: String

    enum CodingKeys: String, CodingKey {
        case id, role, content
    }

    init(id: String = UUID().uuidString, role: String, content: String) {
        self.id = id
        self.role = role
        self.content = content
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // 如果服务端未返回 id，自动生成一个稳定的 UUID
        self.id = (try? container.decode(String.self, forKey: .id)) ?? UUID().uuidString
        self.role = try container.decode(String.self, forKey: .role)
        self.content = try container.decode(String.self, forKey: .content)
    }
}

struct ChatRequest: Encodable {
    let message: String
    let thread_id: String?
}

struct ChatResponse: Codable {
    let answer_markdown: String?
    let summary: String?
    let confidence: Double?
    let followups: [String]?
    let thread_id: String?
}
