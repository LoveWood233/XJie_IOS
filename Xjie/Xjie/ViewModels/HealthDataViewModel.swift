import Foundation

@MainActor
final class HealthDataViewModel: ObservableObject {
    @Published var loading = false
    @Published var summary = ""
    @Published var summaryUpdatedAt = ""
    @Published var generatingSummary = false
    @Published var recordCount = 0
    @Published var examCount = 0
    @Published var showUploadSheet = false
    @Published var showDocumentPicker = false
    @Published var uploadDocType = "record"
    @Published var errorMessage: String?

    private let repository: HealthDataRepositoryProtocol

    init(repository: HealthDataRepositoryProtocol = HealthDataRepository()) {
        self.repository = repository
    }

    func fetchAll() async {
        loading = true
        defer { loading = false }

        let summaryRes = try? await repository.fetchSummary()
        guard !Task.isCancelled else { return }
        summary = summaryRes?.summary_text ?? ""
        if let updatedAt = summaryRes?.updated_at {
            if let date = Utils.parseISO(updatedAt) {
                summaryUpdatedAt = Utils.formatDate(updatedAt)
            }
        }
        recordCount = (try? await repository.fetchDocuments(docType: "record"))?.count ?? 0
        examCount = (try? await repository.fetchDocuments(docType: "exam"))?.count ?? 0
    }

    func generateSummary() async {
        guard !generatingSummary else { return }
        generatingSummary = true
        defer { generatingSummary = false }
        do {
            // TODO: [LLM API] 后端使用 LLM 生成健康总结
            // 如果 LLM 服务未部署，后端返回 fallback 文本
            let res = try await repository.generateSummary()
            summary = res.summary_text ?? ""
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func uploadFile(data: Data, fileName: String) async {
        do {
            try await repository.uploadDocument(data: data, fileName: fileName, docType: uploadDocType)
            await fetchAll()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
