import Foundation

struct ParsedPattern {
    let pathTemplate: String
    let pathPlaceholders: [String]
    let queryPlaceholders: [QueryPlaceholder]

    struct QueryPlaceholder {
        let key: String
        let placeholder: String
    }

    init(_ pattern: String) throws {
        let parts = pattern.split(separator: "?", maxSplits: 1, omittingEmptySubsequences: false)
        self.pathTemplate = parts.first.map(String.init) ?? ""

        self.pathPlaceholders = ParsedPattern.extractPlaceholders(in: pathTemplate)

        if parts.count > 1 {
            let queryPart = String(parts[1])
            self.queryPlaceholders = try ParsedPattern.parseQueryPlaceholders(queryPart)
        } else {
            self.queryPlaceholders = []
        }
    }

    private static func parseQueryPlaceholders(_ query: String) throws -> [QueryPlaceholder] {
        guard !query.isEmpty else { return [] }
        var placeholders: [QueryPlaceholder] = []
        let pairs = query.split(separator: "&")
        for pair in pairs {
            let components = pair.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
            let key = String(components.first ?? "")
            guard !key.isEmpty else {
                throw SimpleError(ko: "쿼리 문자열에 키가 비어 있습니다: \(pair)", en: "Query string contains an empty key: \(pair)")
            }

            let value = components.count > 1 ? String(components[1]) : ""
            guard let placeholder = extractSinglePlaceholder(in: value) else {
                throw SimpleError(ko: "쿼리 값은 반드시 ${name} 형식의 플레이스홀더여야 합니다: \(value)", en: "Query value must use a ${name} placeholder: \(value)")
            }
            placeholders.append(QueryPlaceholder(key: key, placeholder: placeholder))
        }
        return placeholders
    }

    private static func extractPlaceholders(in text: String) -> [String] {
        guard !text.isEmpty else { return [] }
        var results: [String] = []
        var currentIndex = text.startIndex

        while currentIndex < text.endIndex {
            guard let dollarIndex = text[currentIndex...].firstIndex(of: "$") else { break }
            let braceIndex = text.index(after: dollarIndex)
            guard braceIndex < text.endIndex, text[braceIndex] == "{" else {
                currentIndex = text.index(after: dollarIndex)
                continue
            }

            let placeholderStart = text.index(after: braceIndex)
            guard let closingBrace = text[placeholderStart...].firstIndex(of: "}") else { break }
            let name = String(text[placeholderStart..<closingBrace])
            if !name.isEmpty {
                results.append(name)
            }
            currentIndex = text.index(after: closingBrace)
        }
        return results
    }

    private static func extractSinglePlaceholder(in text: String) -> String? {
        guard text.hasPrefix("${"), text.hasSuffix("}"), text.count >= 4 else { return nil }
        let start = text.index(text.startIndex, offsetBy: 2)
        let end = text.index(before: text.endIndex)
        let name = String(text[start..<end])
        return name.isEmpty ? nil : name
    }
}
