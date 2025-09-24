import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

struct RoutePatternMacro: PeerMacro {
    static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // 메타데이터 전용 매크로로 실제 코드는 생성하지 않는다.
        return []
    }
}

struct SchemeRoutableMacro: MemberMacro {
    static func expansion(
        of attribute: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        _ = protocols

        guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
            emitError("@SchemeRoutable 은 열거형에만 적용할 수 있습니다.", on: declaration, in: context)
            return []
        }

        let enumName = enumDecl.name.text
        var builderCalls: [String] = []
        var hasError = false

        for member in enumDecl.memberBlock.members {
            guard let caseDecl = member.decl.as(EnumCaseDeclSyntax.self) else { continue }

            if caseDecl.elements.count > 1 {
                emitError("각 case 선언에는 하나의 case 만 포함되어야 합니다.", on: caseDecl, in: context)
                hasError = true
                continue
            }

            for element in caseDecl.elements {
                guard let attribute = findRoutePatternAttribute(on: caseDecl) else {
                    emitError("각 case 에 @RoutePattern(\"...\") 어노테이션을 지정해야 합니다.", on: element, in: context)
                    hasError = true
                    continue
                }

                guard let patternLiteral = extractStringLiteral(from: attribute, in: context) else {
                    hasError = true
                    continue
                }

                let parsedPattern: ParsedPattern
                do {
                    parsedPattern = try ParsedPattern(patternLiteral)
                } catch {
                    emitError(message(from: error), on: element, in: context)
                    hasError = true
                    continue
                }

                let caseInfo: CaseInfo
                do {
                    caseInfo = try CaseInfo(enumCaseElement: element, pattern: parsedPattern)
                } catch {
                    emitError(message(from: error), on: element, in: context)
                    hasError = true
                    continue
                }

                builderCalls.append(generateBuilderCall(for: caseInfo))
            }
        }

        if hasError { return [] }
        if builderCalls.isEmpty {
            emitError("@SchemeRoutable 은 적어도 하나의 case 와 @RoutePattern 을 필요로 합니다.", on: declaration, in: context)
            return []
        }

        let body = builderCalls
            .map { $0.indented(by: 1) }
            .joined(separator: "\n\n")

        let routerDecl: DeclSyntax = """
        static let router = ApplicationRouter<\(raw: enumName)> { builder in
        \(raw: body)
        }
        """

        return [routerDecl]
    }
}
