import Foundation

class LuaZCompletionProvider {
    private let keywords = [
        "function", "local", "if", "then", "else", "elseif", "end",
        "for", "while", "do", "return", "break", "true", "false", "nil",
        "and", "or", "not"
    ]
    
    private let luazKeywords = [
        "type", "struct", "enum", "const", "import", "export", "async", "await"
    ]
    
    private let builtIns = [
        "print", "type", "tostring", "tonumber", "ipairs", "pairs",
        "table.insert", "table.remove", "table.concat", "table.sort",
        "string.sub", "string.upper", "string.lower", "string.find",
        "math.abs", "math.floor", "math.ceil", "math.random", "math.pi"
    ]
    
    func getCompletions(for text: String, cursorPosition: Int, projectSymbols: [String] = []) -> [Completion] {
        let prefix = extractPrefix(from: text, cursorPosition: cursorPosition)
        
        var completions: [Completion] = []
        
        completions.append(contentsOf: keywords.filter { $0.hasPrefix(prefix) }.map {
            Completion(text: $0, kind: .keyword, detail: nil)
        })
        
        completions.append(contentsOf: luazKeywords.filter { $0.hasPrefix(prefix) }.map {
            Completion(text: $0, kind: .keyword, detail: "LuaZ")
        })
        
        completions.append(contentsOf: builtIns.filter { $0.hasPrefix(prefix) }.map {
            Completion(text: $0, kind: .function, detail: "Built-in")
        })
        
        completions.append(contentsOf: projectSymbols.filter { $0.hasPrefix(prefix) }.map {
            Completion(text: $0, kind: .variable, detail: "Project")
        })
        
        return completions.sorted { $0.text < $1.text }
    }
    
    private func extractPrefix(from text: String, cursorPosition: Int) -> String {
        let index = text.index(text.startIndex, offsetBy: cursorPosition)
        let substring = String(text[..<index])
        
        var prefix = ""
        for char in substring.reversed() {
            if char.isWhitespace || char == "(" || char == ")" || char == "{" || char == "}" || char == "[" || char == "]" || char == "," || char == ";" {
                break
            }
            prefix = String(char) + prefix
        }
        
        return prefix
    }
}

struct Completion {
    let text: String
    let kind: CompletionKind
    let detail: String?
    
    enum CompletionKind {
        case keyword
        case function
        case variable
        case type
    }
}
