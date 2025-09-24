@attached(member, names: named(router))
public macro SchemeRoutable() = #externalMacro(module: "SchemeRouteMacros", type: "SchemeRoutableMacro")

@attached(peer)
public macro SchemePattern(_ pattern: String) = #externalMacro(module: "SchemeRouteMacros", type: "SchemePatternMacro")
