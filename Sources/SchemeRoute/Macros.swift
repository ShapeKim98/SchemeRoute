@attached(member, names: named(router))
public macro SchemeRoutable() = #externalMacro(module: "SchemeRouteMacros", type: "SchemeRoutableMacro")

@attached(peer)
public macro RoutePattern(_ pattern: String) = #externalMacro(module: "SchemeRouteMacros", type: "RoutePatternMacro")
