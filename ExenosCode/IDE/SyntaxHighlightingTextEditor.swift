import SwiftUI

struct SyntaxHighlightingTextEditor: View {
    @Binding var text: String

    private let keywords: Set<String> = ["function", "end", "if", "then", "else", "for", "while", "local", "return"]

    var body: some View {
        ZStack(alignment: .topLeading) {
            highlightedText
                .padding(.horizontal, 6)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            TextEditor(text: $text)
                .font(.system(.body, design: .monospaced))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .scrollContentBackground(.hidden)
                .foregroundColor(.clear)
                .tint(.primary)
                .padding(.horizontal, 2)
                .padding(.vertical, 1)
        }
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var highlightedText: Text {
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false)
        return lines.enumerated().reduce(Text("")) { partial, item in
            let (index, line) = item
            let rendered = renderLine(String(line))
            if index == lines.count - 1 {
                return partial + rendered
            }
            return partial + rendered + Text("\n")
        }
        .font(.system(.body, design: .monospaced))
    }

    private func renderLine(_ line: String) -> Text {
        guard let commentIndex = line.firstIndex(of: "-"),
              line.index(after: commentIndex) < line.endIndex,
              line[line.index(after: commentIndex)] == "-" else {
            return renderTokens(line)
        }

        let codePart = String(line[..<commentIndex])
        let commentPart = String(line[commentIndex...])
        return renderTokens(codePart) + Text(commentPart).foregroundColor(.gray)
    }

    private func renderTokens(_ source: String) -> Text {
        if source.isEmpty {
            return Text("")
        }

        let parts = source.components(separatedBy: .whitespaces)
        return parts.enumerated().reduce(Text("")) { partial, item in
            let (index, token) = item
            let base = keywords.contains(token) ? Text(token).foregroundColor(.blue) : Text(token).foregroundColor(.primary)
            if index == parts.count - 1 {
                return partial + base
            }
            return partial + base + Text(" ")
        }
    }
}
