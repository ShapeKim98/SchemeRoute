import Foundation
import SwiftSyntax

extension TypeSyntax {
    var trimmedDescription: String {
        description.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension String {
    var stringLiteral: String {
        let escaped = self
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        return "\"\(escaped)\""
    }

    func indented(by level: Int) -> String {
        guard level > 0 else { return self }
        let indent = String(repeating: "    ", count: level)
        return self
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { indent + $0 }
            .joined(separator: "\n")
    }
}
