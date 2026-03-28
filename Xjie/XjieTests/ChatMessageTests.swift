import XCTest
@testable import Xjie

/// ChatMessage 模型测试（BUG-01 回归测试）
final class ChatMessageTests: XCTestCase {

    func testDecodeWithServerId() throws {
        let json = """
        {"id": "server-123", "role": "user", "content": "hello"}
        """.data(using: .utf8)!

        let msg = try JSONDecoder().decode(ChatMessage.self, from: json)
        XCTAssertEqual(msg.id, "server-123")
        XCTAssertEqual(msg.role, "user")
        XCTAssertEqual(msg.content, "hello")
    }

    func testDecodeWithoutIdGeneratesUUID() throws {
        let json = """
        {"role": "assistant", "content": "hi"}
        """.data(using: .utf8)!

        let msg = try JSONDecoder().decode(ChatMessage.self, from: json)
        XCTAssertFalse(msg.id.isEmpty, "id 应自动生成 UUID")
        XCTAssertEqual(msg.role, "assistant")
    }

    /// BUG-01 回归：id 必须是存储属性，多次访问返回同一值
    func testIdIsStableAcrossAccesses() throws {
        let json = """
        {"role": "user", "content": "test"}
        """.data(using: .utf8)!

        let msg = try JSONDecoder().decode(ChatMessage.self, from: json)
        let id1 = msg.id
        let id2 = msg.id
        XCTAssertEqual(id1, id2, "BUG-01: id 必须是存储属性，多次访问应返回同一值")
    }

    func testDecodeMultipleMessagesHaveUniqueIds() throws {
        let json = """
        [
            {"role": "user", "content": "q1"},
            {"role": "assistant", "content": "a1"},
            {"role": "user", "content": "q2"}
        ]
        """.data(using: .utf8)!

        let msgs = try JSONDecoder().decode([ChatMessage].self, from: json)
        let ids = Set(msgs.map(\.id))
        XCTAssertEqual(ids.count, 3, "每条消息应有唯一 id")
    }
}
