@attached(member, names: named(router))
@attached(extension, conformances: SchemeRoute)
public macro SchemeRoutable() = #externalMacro(module: "SchemeRouteMacros", type: "SchemeRoutableMacro")

@attached(peer)
public macro SchemePattern(_ pattern: String) = #externalMacro(module: "SchemeRouteMacros", type: "SchemePatternMacro")
