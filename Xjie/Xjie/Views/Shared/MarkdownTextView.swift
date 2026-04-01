import SwiftUI

/// Markdown 渲染文本视图 — 使用 iOS 15+ AttributedString
struct MarkdownTextView: View {
    let text: String

    var body: some View {
        if let attributed = try? AttributedString(markdown: text, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
            Text(attributed)
                .font(.subheadline)
                .foregroundColor(.appText)
                .multilineTextAlignment(.leading)
        } else {
            Text(text)
                .font(.subheadline)
                .foregroundColor(.appText)
                .multilineTextAlignment(.leading)
        }
    }
}
