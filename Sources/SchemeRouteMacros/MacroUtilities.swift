import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

func findRoutePatternAttribute(on caseDecl: EnumCaseDeclSyntax) -> AttributeSyntax? {
    attribute(named: "RoutePattern", in: caseDecl.attributes)
}

func attribute(named name: String, in attributes: AttributeListSyntax?) -> AttributeSyntax? {
    guard let attributes else { return nil }
    for element in attributes {
        guard let attribute = element.as(AttributeSyntax.self) else { continue }
        if attribute.attributeName.trimmedDescription == name {
            return attribute
        }
    }
    return nil
}

func extractStringLiteral<C: MacroExpansionContext>(
    from attribute: AttributeSyntax,
    in context: C
) -> String? {
    guard let arguments = attribute.arguments,
          case .argumentList(let list) = arguments,
          let first = list.first,
          let literal = first.expression.as(StringLiteralExprSyntax.self),
          literal.segments.count == 1,
          let segment = literal.segments.first?.as(StringSegmentSyntax.self) else {
        emitError(localized(ko: "@RoutePattern 은 단일 문자열 리터럴을 인자로 받아야 합니다.", en: "@RoutePattern must take a single string literal argument."), on: attribute, in: context)
        return nil
    }
    return segment.content.text
}
