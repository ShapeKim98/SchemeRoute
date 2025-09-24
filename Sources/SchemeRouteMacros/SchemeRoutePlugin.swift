import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct SchemeRoutePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        SchemeRoutableMacro.self,
        RoutePatternMacro.self,
    ]
}
