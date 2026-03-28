import Foundation

/// MIME 类型推断 — 消除各 ViewModel 中的重复逻辑
enum MIMETypeHelper {
    static func mimeType(forExtension ext: String) -> String {
        switch ext.lowercased() {
        case "jpg", "jpeg": return "image/jpeg"
        case "png": return "image/png"
        case "csv": return "text/csv"
        case "pdf": return "application/pdf"
        default: return "application/octet-stream"
        }
    }

    static func mimeType(forFileName fileName: String) -> String {
        let ext = (fileName as NSString).pathExtension
        return mimeType(forExtension: ext)
    }
}
