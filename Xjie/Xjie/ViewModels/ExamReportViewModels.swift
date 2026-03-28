import Foundation

@MainActor
final class ExamReportListViewModel: ObservableObject {
    @Published var loading = false
    @Published var items: [HealthDocument] = []
    @Published var showDocumentPicker = false
    @Published var showDeleteAlert = false
    @Published var deleteId: String?
    @Published var errorMessage: String?

    private let repository: HealthDataRepositoryProtocol

    init(repository: HealthDataRepositoryProtocol = HealthDataRepository()) {
        self.repository = repository
    }

    func fetchList() async {
        loading = true
        defer { loading = false }
        do {
            let fetched = try await repository.fetchDocuments(docType: "exam")
            guard !Task.isCancelled else { return }
            items = fetched
        } catch {
            guard !Task.isCancelled else { return }
            errorMessage = error.localizedDescription
        }
    }

    func uploadExam(data: Data, fileName: String) async {
        do {
            try await repository.uploadDocument(data: data, fileName: fileName, docType: "exam")
            await fetchList()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func confirmDelete() async {
        guard let id = deleteId else { return }
        do {
            try await repository.deleteDocument(id: id)
            await fetchList()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
