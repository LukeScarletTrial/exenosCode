import SwiftUI

struct CodeEditorView: View {
    let file: ProjectFile
    let project: Project
    @State private var content: String
    @State private var selectedRange: NSRange = NSRange(location: 0, length: 0)
    @FocusState private var isFocused: Bool
    
    init(file: ProjectFile, project: Project) {
        self.file = file
        self.project = project
        _content = State(initialValue: file.content)
    }
    
    var body: some View {
        ZStack {
            Color(red: 0.04, green: 0.04, blue: 0.06)
            
            VStack(spacing: 0) {
                SyntaxHighlightingTextEditor(
                    text: $content,
                    selectedRange: $selectedRange,
                    fileType: file.fileType,
                    isFocused: _isFocused
                )
                .padding(16)
                
                Divider()
                
                DiagnosticsPanel(diagnostics: [], file: file)
            }
        }
        .onChange(of: content) { oldValue, newValue in
            saveContent(newValue)
        }
    }
    
    private func saveContent(_ content: String) {
        let projectStore = ProjectStore()
        projectStore.saveProjectFile(file, content: content, in: project)
    }
}

struct SyntaxHighlightingTextEditor: UIViewRepresentable {
    @Binding var text: String
    @Binding var selectedRange: NSRange
    let fileType: FileType
    @FocusState var isFocused: Bool
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.font = UIFont(name: "Menlo", size: 14)
        textView.backgroundColor = UIColor(red: 0.04, green: 0.04, blue: 0.06)
        textView.textColor = UIColor.white
        textView.autocapitalizationType = .none
        textView.autocorrectionType = .no
        textView.smartDashesType = .no
        textView.smartQuotesType = .no
        textView.spellCheckingType = .no
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        textView.delegate = context.coordinator
        textView.text = text
        
        let toolbar = UIToolbar()
        toolbar.items = [
            UIBarButtonItem(title: "Tab", style: .plain, target: context.coordinator, action: #selector(Coordinator.insertTab))
        ]
        toolbar.sizeToFit()
        textView.inputAccessoryView = toolbar
        
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
        
        if isFocused && !uiView.isFirstResponder {
            uiView.becomeFirstResponder()
        } else if !isFocused && uiView.isFirstResponder {
            uiView.resignFirstResponder()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: SyntaxHighlightingTextEditor
        
        init(_ parent: SyntaxHighlightingTextEditor) {
            self.parent = parent
        }
        
        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
            applySyntaxHighlighting(to: textView)
        }
        
        func textViewDidChangeSelection(_ textView: UITextView) {
            parent.selectedRange = textView.selectedRange
        }
        
        @objc func insertTab() {
            if let textView = parent.text as? NSString {
                let range = parent.selectedRange
                let insertion = "    "
                parent.text = textView.replacingCharacters(in: range, with: insertion)
                parent.selectedRange = NSRange(location: range.location + insertion.count, length: 0)
            }
        }
        
        private func applySyntaxHighlighting(to textView: UITextView) {
            let attributedString = NSMutableAttributedString(string: textView.text)
            let fullRange = NSRange(location: 0, length: attributedString.length)
            
            attributedString.addAttribute(.foregroundColor, value: UIColor.white, range: fullRange)
            
            let keywords = ["function", "local", "if", "then", "else", "elseif", "end", "for", "while", "do", "return", "break", "true", "false", "nil", "and", "or", "not"]
            let luazKeywords = ["type", "struct", "enum", "const", "import", "export", "async", "await"]
            
            for keyword in keywords + luazKeywords {
                let pattern = "\\b\(keyword)\\b"
                let regex = try? NSRegularExpression(pattern: pattern, options: [])
                
                regex?.enumerateMatches(in: textView.text, options: [], range: fullRange) { match, _, _ in
                    if let range = match?.range {
                        attributedString.addAttribute(.foregroundColor, value: UIColor(red: 0.55, green: 0.35, blue: 1, alpha: 1), range: range)
                    }
                }
            }
            
            let stringPattern = "\"[^\"]*\""
            let stringRegex = try? NSRegularExpression(pattern: stringPattern, options: [])
            stringRegex?.enumerateMatches(in: textView.text, options: [], range: fullRange) { match, _, _ in
                if let range = match?.range {
                    attributedString.addAttribute(.foregroundColor, value: UIColor(red: 0, green: 0.7, blue: 0.4, alpha: 1), range: range)
                }
            }
            
            let numberPattern = "\\b\\d+\\.?\\d*\\b"
            let numberRegex = try? NSRegularExpression(pattern: numberPattern, options: [])
            numberRegex?.enumerateMatches(in: textView.text, options: [], range: fullRange) { match, _, _ in
                if let range = match?.range {
                    attributedString.addAttribute(.foregroundColor, value: UIColor(red: 0, green: 0.94, blue: 1, alpha: 1), range: range)
                }
            }
            
            let commentPattern = "--[^\\n]*"
            let commentRegex = try? NSRegularExpression(pattern: commentPattern, options: [])
            commentRegex?.enumerateMatches(in: textView.text, options: [], range: fullRange) { match, _, _ in
                if let range = match?.range {
                    attributedString.addAttribute(.foregroundColor, value: UIColor(red: 0.4, green: 0.4, blue: 0.5, alpha: 1), range: range)
                }
            }
            
            textView.attributedText = attributedString
        }
    }
}

struct DiagnosticsPanel: View {
    let diagnostics: [Diagnostic]
    let file: ProjectFile
    
    var body: some View {
        if diagnostics.isEmpty {
            HStack {
                Spacer()
                Text("No diagnostics")
                    .font(.system(size: 12))
                    .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.5))
                Spacer()
            }
            .padding(8)
            .background(Color(red: 0.08, green: 0.08, blue: 0.12))
        } else {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(diagnostics) { diagnostic in
                    HStack(spacing: 8) {
                        Image(systemName: diagnostic.severity == .error ? "xmark.circle.fill" : "exclamationmark.triangle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(diagnostic.severity == .error ? Color(red: 1, green: 0.35, blue: 0.55) : Color(red: 1, green: 0.8, blue: 0))
                        
                        Text(diagnostic.message)
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        if let luazLine = diagnostic.luazLine {
                            Text("Line \(luazLine)")
                                .font(.system(size: 10))
                                .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.6))
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(red: 0.08, green: 0.08, blue: 0.12))
                }
            }
        }
    }
}
