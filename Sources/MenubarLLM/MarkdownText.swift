import SwiftUI

/// A very lightweight, recursive markdown renderer.
/// Supports bold (**text**) and inline code (`text`). Preserves line breaks.
struct MarkdownText: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(text.components(separatedBy: "\n").enumerated()), id: \.offset) { _, line in
                inlineText(for: line)
            }
        }
    }

    /// Recursively parses a single line for inline bold and code spans.
    private func inlineText(for line: String) -> Text {
        // Bold: **text**
        if let openRange = line.range(of: "**") {
            let before = String(line[..<openRange.lowerBound])
            let after = String(line[openRange.upperBound...])
            if let closeRange = after.range(of: "**") {
                let boldText = String(after[..<closeRange.lowerBound])
                let rest = String(after[closeRange.upperBound...])
                return Text(before) + Text(boldText).bold() + inlineText(for: rest)
            }
        }

        // Inline code: `text`
        if let openRange = line.range(of: "`") {
            let before = String(line[..<openRange.lowerBound])
            let after = String(line[openRange.upperBound...])
            if let closeRange = after.range(of: "`") {
                let codeText = String(after[..<closeRange.lowerBound])
                let rest = String(after[closeRange.upperBound...])
                return Text(before)
                    + Text(codeText)
                        .font(.system(.body, design: .monospaced))
                        + inlineText(for: rest)
            }
        }

        return Text(line)
    }
}
