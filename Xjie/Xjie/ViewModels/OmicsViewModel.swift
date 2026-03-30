import Foundation

/// 代谢组学分析结果
struct MetabolomicsAnalysis: Codable {
    let summary: String
    let analysis: String
    let riskLevel: String       // "低风险" / "中风险" / "高风险"
    let metabolites: [MetaboliteResult]?

    enum CodingKeys: String, CodingKey {
        case summary, analysis
        case riskLevel = "risk_level"
        case metabolites
    }
}

struct MetaboliteResult: Codable, Identifiable {
    var id: String { name }
    let name: String
    let value: Double?
    let unit: String?
    let status: String?     // "normal" / "high" / "low"
}

/// 模型分析结果占位
struct ModelAnalysisResult: Codable {
    let taskId: String
    let status: String          // "pending" / "running" / "completed" / "failed"
    let result: ModelResultData?

    enum CodingKeys: String, CodingKey {
        case taskId = "task_id"
        case status, result
    }
}

struct ModelResultData: Codable {
    let pathways: [String]?
    let biomarkers: [String]?
    let riskScore: Double?

    enum CodingKeys: String, CodingKey {
        case pathways, biomarkers
        case riskScore = "risk_score"
    }
}

@MainActor
final class OmicsViewModel: ObservableObject {
    @Published var showFilePicker = false
    @Published var uploadedFileName: String?
    @Published var analyzing = false
    @Published var analysisResult: MetabolomicsAnalysis?
    @Published var errorMessage: String?

    private var pickedFileData: Data?
    private var pickedMimeType: String = "text/csv"
    private let api: APIServiceProtocol

    init(api: APIServiceProtocol = APIService.shared) {
        self.api = api
    }

    func handlePickedFile(_ url: URL) {
        guard let data = try? Data(contentsOf: url) else {
            errorMessage = "无法读取文件"
            return
        }
        let ext = url.pathExtension.lowercased()
        pickedMimeType = switch ext {
        case "csv": "text/csv"
        case "xlsx", "xls": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        case "pdf": "application/pdf"
        default: "application/octet-stream"
        }
        pickedFileData = data
        uploadedFileName = url.lastPathComponent
        Task { await uploadAndAnalyze() }
    }

    func clearUpload() {
        uploadedFileName = nil
        pickedFileData = nil
        analysisResult = nil
    }

    private func uploadAndAnalyze() async {
        guard let data = pickedFileData, let name = uploadedFileName else { return }
        analyzing = true
        defer { analyzing = false }

        do {
            let responseData = try await api.uploadFile(
                "/api/omics/metabolomics/upload",
                fileData: data,
                fileName: name,
                mimeType: pickedMimeType,
                formData: [:]
            )
            let result = try JSONDecoder().decode(MetabolomicsAnalysis.self, from: responseData)
            analysisResult = result
        } catch {
            errorMessage = "分析失败: \(error.localizedDescription)"
        }
    }
}
