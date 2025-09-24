import SwiftDiagnostics
import Foundation
import SwiftSyntax
import SwiftSyntaxMacros

private enum LocalePreference {
    static let isKorean: Bool = {
        let preferred = Locale.preferredLanguages.map { $0.lowercased() }
        if let first = preferred.first, first.hasPrefix("ko") {
            return true
        }
        if let code = Locale.current.languageCode?.lowercased(), code.hasPrefix("ko") {
            return true
        }
        return false
    }()
}

func localized(ko: String, en: String) -> String {
    LocalePreference.isKorean ? ko : en
}

struct SimpleError: LocalizedError {
    private let messageKO: String
    private let messageEN: String

    init(_ message: String) {
        self.messageKO = message
        self.messageEN = message
    }

    init(ko: String, en: String) {
        self.messageKO = ko
        self.messageEN = en
    }

    var errorDescription: String? {
        localized(ko: messageKO, en: messageEN)
    }
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
    if let simple = error as? SimpleError { return simple.localizedDescription }
    if let localized = error as? LocalizedError, let description = localized.errorDescription {
        return description
    }
    return String(describing: error)
}
