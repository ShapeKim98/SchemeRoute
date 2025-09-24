import SwiftDiagnostics
import Foundation
import SwiftSyntax
import SwiftSyntaxMacros

struct SimpleError: LocalizedError {
    let message: String
    init(_ message: String) { self.message = message }
    var errorDescription: String? { message }
}

struct SimpleDiagnostic: DiagnosticMessage {
    let message: String
    let diagnosticID = MessageID(domain: "SchemeRoute", id: "scheme-route")
    let severity: DiagnosticSeverity = .error
}

func emitError<C: MacroExpansionContext>(
    _ message: String,
    on node: some SyntaxProtocol,
    in context: C
) {
    let diagnostic = Diagnostic(node: Syntax(node), message: SimpleDiagnostic(message: message))
    context.diagnose(diagnostic)
}

func message(from error: Error) -> String {
    if let simple = error as? SimpleError { return simple.message }
    if let localized = error as? LocalizedError, let description = localized.errorDescription {
        return description
    }
    return String(describing: error)
}
