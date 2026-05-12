import Foundation

class LuaZTranspiler {
    private var lineMap: [Int: Int] = [:]
    private var currentLuaZLine: Int = 0
    
    func transpile(_ luazCode: String) -> (luaCode: String, lineMap: [Int: Int]) {
        lineMap.removeAll()
        currentLuaZLine = 0
        
        var luaCode = luazCode
        luaCode = transpileTypeAnnotations(luaCode)
        luaCode = transpileStructSyntax(luaCode)
        luaCode = transpileConstSyntax(luaCode)
        luaCode = transpileImportExport(luaCode)
        luaCode = transpileAsyncAwait(luaCode)
        luaCode = transpileArrowFunctions(luaCode)
        
        return (luaCode, lineMap)
    }
    
    private func transpileTypeAnnotations(_ code: String) -> String {
        let pattern = "([a-zA-Z_][a-zA-Z0-9_]*)\\s*:\\s*([a-zA-Z_][a-zA-Z0-9_\\[\\]\\{\\}]*)"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: code.utf16.count)
        
        var result = code
        var offset = 0
        
        regex?.enumerateMatches(in: code, options: [], range: range) { match, _, _ in
            guard let match = match else { return }
            let nsRange = match.range(at: 0)
            let swiftRange = Range(nsRange, in: code)!
            
            let beforeColon = code[swiftRange].split(separator: ":").first ?? ""
            let replacement = String(beforeColon)
            
            let luaRange = NSRange(location: nsRange.location - offset, length: nsRange.length)
            result = (result as NSString).replacingCharacters(in: luaRange, with: replacement)
            offset += nsRange.length - replacement.count
        }
        
        return result
    }
    
    private func transpileStructSyntax(_ code: String) -> String {
        let pattern = "struct\\s+([a-zA-Z_][a-zA-Z0-9_]*)\\s*\\{([^}]*)\\}"
        let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators])
        let range = NSRange(location: 0, length: code.utf16.count)
        
        var result = code
        var offset = 0
        
        regex?.enumerateMatches(in: code, options: [], range: range) { match, _, _ in
            guard let match = match else { return }
            let nsRange = match.range(at: 0)
            let swiftRange = Range(nsRange, in: code)!
            let structBody = code[swiftRange]
            
            let lines = structBody.split(separator: "\n")
            var fields: [String] = []
            
            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty && !trimmed.hasPrefix("}") {
                    let parts = trimmed.split(separator: ":")
                    if let fieldName = parts.first {
                        fields.append("    \(fieldName) = nil")
                    }
                }
            }
            
            let replacement = "\(String(structBody.split(separator: "{").first ?? "")) = {\n\(fields.joined(separator: ",\n"))\n}"
            
            let luaRange = NSRange(location: nsRange.location - offset, length: nsRange.length)
            result = (result as NSString).replacingCharacters(in: luaRange, with: replacement)
            offset += nsRange.length - replacement.count
        }
        
        return result
    }
    
    private func transpileConstSyntax(_ code: String) -> String {
        return code.replacingOccurrences(of: "const ", with: "local ")
    }
    
    private func transpileImportExport(_ code: String) -> String {
        var result = code
        
        let importPattern = "import\\s+\"([^\"]+)\""
        let importRegex = try? NSRegularExpression(pattern: importPattern, options: [])
        let importRange = NSRange(location: 0, length: result.utf16.count)
        
        result = importRegex?.stringByReplacingMatches(in: result, options: [], range: importRange, withTemplate: "require(\"$1\")") ?? result
        
        let exportPattern = "export\\s+(function|const|local)\\s+([a-zA-Z_][a-zA-Z0-9_]*)"
        let exportRegex = try? NSRegularExpression(pattern: exportPattern, options: [])
        let exportRange = NSRange(location: 0, length: result.utf16.count)
        
        result = exportRegex?.stringByReplacingMatches(in: result, options: [], range: exportRange, withTemplate: "$2") ?? result
        
        return result
    }
    
    private func transpileAsyncAwait(_ code: String) -> String {
        var result = code
        
        let asyncPattern = "async\\s+function"
        result = result.replacingOccurrences(of: asyncPattern, with: "function")
        
        let awaitPattern = "await\\s+"
        result = result.replacingOccurrences(of: awaitPattern, with: "")
        
        return result
    }
    
    private func transpileArrowFunctions(_ code: String) -> String {
        let pattern = "\\(([a-zA-Z_][a-zA-Z0-9_]*(,\\s*[a-zA-Z_][a-zA-Z0-9_]*)*)?\\)\\s*=>"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: code.utf16.count)
        
        var result = code
        var offset = 0
        
        regex?.enumerateMatches(in: code, options: [], range: range) { match, _, _ in
            guard let match = match else { return }
            let nsRange = match.range(at: 0)
            let swiftRange = Range(nsRange, in: code)!
            let arrowFunc = code[swiftRange]
            
            let params = arrowFunc.dropFirst().dropLast().trimmingCharacters(in: .whitespaces)
            let replacement = "function(\(params))"
            
            let luaRange = NSRange(location: nsRange.location - offset, length: nsRange.length)
            result = (result as NSString).replacingCharacters(in: luaRange, with: replacement)
            offset += nsRange.length - replacement.count
        }
        
        return result
    }
    
    func mapLuaLineToLuaZ(_ luaLine: Int) -> Int? {
        for (luazLine, mappedLuaLine) in lineMap {
            if mappedLuaLine == luaLine {
                return luazLine
            }
        }
        return nil
    }
}
