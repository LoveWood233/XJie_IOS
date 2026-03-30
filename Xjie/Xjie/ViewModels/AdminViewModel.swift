import Foundation

// MARK: - Admin Models

struct AdminStats: Decodable {
    let total_users: Int
    let active_users_7d: Int
    let total_conversations: Int
    let total_messages: Int
    let total_omics_uploads: Int
    let total_meals: Int
}

struct AdminUserItem: Decodable, Identifiable {
    let id: Int
    let phone: String
    let username: String?
    let is_admin: Bool
    let created_at: String?
    let conversation_count: Int
    let message_count: Int
    let last_active: String?
}

struct AdminConversationItem: Decodable, Identifiable {
    let id: Int
    let user_id: Int
    let username: String?
    let title: String?
    let message_count: Int
    let created_at: String?
    let updated_at: String?
}

struct AdminOmicsItem: Decodable, Identifiable {
    let id: Int
    let user_id: Int
    let username: String?
    let omics_type: String
    let file_name: String?
    let file_size: Int?
    let risk_level: String?
    let llm_summary: String?
    let created_at: String?
}

// MARK: - ViewModel

@MainActor
final class AdminViewModel: ObservableObject {
    @Published var stats: AdminStats?
    @Published var users: [AdminUserItem] = []
    @Published var conversations: [AdminConversationItem] = []
    @Published var omicsUploads: [AdminOmicsItem] = []
    @Published var loading = false
    @Published var errorMessage: String?

    private let api: APIServiceProtocol

    init(api: APIServiceProtocol = APIService.shared) {
        self.api = api
    }

    func fetchStats() async {
        loading = true
        defer { loading = false }
        do {
            stats = try await api.get("/api/admin/stats")
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func fetchUsers() async {
        do {
            users = try await api.get("/api/admin/users?page=1&size=100")
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func fetchConversations() async {
        do {
            conversations = try await api.get("/api/admin/conversations?page=1&size=100")
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func fetchOmics() async {
        do {
            omicsUploads = try await api.get("/api/admin/omics?page=1&size=100")
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func fetchAll() async {
        loading = true
        defer { loading = false }
        async let s: Void = fetchStats()
        async let u: Void = fetchUsers()
        async let c: Void = fetchConversations()
        async let o: Void = fetchOmics()
        _ = await (s, u, c, o)
    }
}
