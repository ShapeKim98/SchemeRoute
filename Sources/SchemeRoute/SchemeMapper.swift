import Foundation

/// 라우트 매칭/렌더링을 담당하는 스킴 URL 매퍼
public final class SchemeMapper<Route> {
    public struct Pattern {
        public let matcher: PathPattern
        public let makeRoute: ([String: String]) -> Route?
        public let parameters: (Route) -> [String: String]?

        public init(
            matcher: PathPattern,
            makeRoute: @escaping ([String: String]) -> Route?,
            parameters: @escaping (Route) -> [String: String]?
        ) {
            self.matcher = matcher
            self.makeRoute = makeRoute
            self.parameters = parameters
        }
    }

    public struct Builder {
        fileprivate var patterns: [Pattern] = []

        public init() {}

        public mutating func register(
            _ template: String,
            queryKeys: [String] = [],
            match: @escaping ([String: String]) -> Route?,
            render: @escaping (Route) -> [String: String]?
        ) {
            let pattern = PathPattern(template: template, queryKeys: queryKeys)
            patterns.append(Pattern(matcher: pattern, makeRoute: match, parameters: render))
        }

        public mutating func register<Value>(
            _ template: String,
            queryKeys: [String] = [],
            casePath: CasePath<Route, Value>,
            decode: @escaping ([String: String]) -> Value?,
            encode: @escaping (Value) -> [String: String]
        ) {
            register(
                template,
                queryKeys: queryKeys,
                match: { params in
                    guard let value = decode(params) else { return nil }
                    return casePath.embed(value)
                },
                render: { route in
                    guard let value = casePath.extract(route) else { return nil }
                    return encode(value)
                }
            )
        }

        public mutating func register(
            _ template: String,
            route: Route
        ) where Route: Equatable {
            register(
                template,
                match: { _ in route },
                render: { candidate in
                    candidate == route ? [:] : nil
                }
            )
        }
    }

    private let patterns: [Pattern]
    private let defaultScheme: String?
    private let defaultHost: String?
    private let includesSchemeInTemplate: Bool
    private let includesHostInTemplate: Bool

    public init(
        patterns: [Pattern],
        defaultScheme: String? = nil,
        defaultHost: String? = nil,
        includesSchemeInTemplate: Bool = false,
        includesHostInTemplate: Bool = true
    ) {
        self.patterns = patterns
        self.defaultScheme = defaultScheme.nonEmpty
        self.defaultHost = defaultHost.nonEmpty
        self.includesSchemeInTemplate = includesSchemeInTemplate
        self.includesHostInTemplate = includesHostInTemplate
    }

    public convenience init(
        defaultScheme: String? = nil,
        defaultHost: String? = nil,
        includesSchemeInTemplate: Bool = false,
        includesHostInTemplate: Bool = true,
        _ configure: (inout Builder) -> Void
    ) {
        var builder = Builder()
        configure(&builder)
        self.init(
            patterns: builder.patterns,
            defaultScheme: defaultScheme,
            defaultHost: defaultHost,
            includesSchemeInTemplate: includesSchemeInTemplate,
            includesHostInTemplate: includesHostInTemplate
        )
    }

    public func route(from rawValue: String) -> Route? {
        if !includesSchemeInTemplate,
           rawValue.contains("://"),
           let url = URL(string: rawValue) {
            return route(from: url)
        }

        let (path, query) = Self.split(rawValue: rawValue)
        for pattern in patterns {
            guard let params = pattern.matcher.match(path: path, query: query) else { continue }
            if let route = pattern.makeRoute(params) {
                return route
            }
        }
        return nil
    }

    public func route(from url: URL) -> Route? {
        for candidate in normalizedCandidates(from: url) {
            if let route = route(from: candidate) {
                return route
            }
        }
        return nil
    }

    public func rawValue(for route: Route) -> String? {
        for pattern in patterns {
            guard let params = pattern.parameters(route) else { continue }
            guard let rendered = pattern.matcher.render(params: params) else { continue }
            return Self.join(path: rendered.path, queryItems: rendered.query)
        }
        return nil
    }

    public func url(for route: Route, scheme: String?, host: String?) -> URL? {
        guard let rawValue = rawValue(for: route) else { return nil }

        if let components = URLComponents(string: rawValue), components.scheme != nil {
            return components.url
        }

        let parts = rawValue.split(separator: "?", maxSplits: 1, omittingEmptySubsequences: false).map(String.init)
        let pathPart = parts.first ?? ""
        let queryPart = parts.count > 1 ? parts[1] : nil

        var components = URLComponents()
        let effectiveScheme = scheme ?? defaultScheme
        let effectiveHost = host ?? defaultHost
        components.scheme = effectiveScheme

        if includesHostInTemplate {
            let decomposition = Self.decomposeHostAndPath(from: pathPart)
            if let explicitHost = decomposition.host {
                components.host = explicitHost
                components.path = decomposition.path.isEmpty ? "" : "/" + decomposition.path
            } else {
                components.host = effectiveHost
                components.path = decomposition.path.isEmpty ? "/" : "/" + decomposition.path
            }
        } else {
            components.host = effectiveHost
            if pathPart.hasPrefix("/") {
                components.path = pathPart
            } else {
                components.path = pathPart.isEmpty ? "" : "/" + pathPart
            }
        }

        if let queryPart {
            components.percentEncodedQuery = queryPart
        }
        return components.url
    }

    public static func normalize(url: URL) -> String {
        guard let components = normalizedComponents(for: url) else {
            return url.absoluteString
        }

        let hostPrefixed = hostPrefixedPath(from: components)
        return appendQuery(components.percentEncodedQuery, to: hostPrefixed)
    }

    private static func split(rawValue: String) -> (path: String, query: [String: String]) {
        let components = rawValue.split(separator: "?", maxSplits: 1, omittingEmptySubsequences: false).map(String.init)
        let path = components.first ?? ""
        let query = components.count > 1 ? parseQuery(components[1]) : [:]
        return (path, query)
    }

    private static func parseQuery(_ qs: String) -> [String: String] {
        guard !qs.isEmpty else { return [:] }
        var dict: [String: String] = [:]
        for pair in qs.split(separator: "&") {
            let kv = pair.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false).map(String.init)
            let key = kv.first?.removingPercentEncoding ?? ""
            let value = (kv.count > 1 ? kv[1] : "").removingPercentEncoding ?? ""
            dict[key] = value
        }
        return dict
    }

    private static func join(path: String, queryItems: [URLQueryItem]) -> String {
        guard !queryItems.isEmpty else { return path }
        var components = URLComponents()
        components.queryItems = queryItems
        let encodedQuery = components.percentEncodedQuery ?? ""
        if path.isEmpty {
            return encodedQuery.isEmpty ? path : "?\(encodedQuery)"
        }
        return encodedQuery.isEmpty ? path : "\(path)?\(encodedQuery)"
    }

    private func normalizedCandidates(from url: URL) -> [String] {
        guard let components = Self.normalizedComponents(for: url) else {
            return [url.absoluteString]
        }

        if let expectedScheme = defaultScheme,
           let actualScheme = components.scheme,
           !Self.caseInsensitiveEqual(expectedScheme, actualScheme) {
            return []
        }

        if !includesHostInTemplate,
           let expectedHost = defaultHost,
           let actualHost = components.host,
           !actualHost.isEmpty,
           !Self.caseInsensitiveEqual(expectedHost, actualHost) {
            return []
        }

        let hostPrefixed = Self.hostPrefixedPath(from: components)
        let pathOnly = Self.trimmedPath(from: components)
        let hostOnly = components.host ?? ""
        let query = components.percentEncodedQuery

        var results: [String] = []

        if includesSchemeInTemplate, let absolute = components.url?.absoluteString {
            results.append(absolute)
        }

        let hostCandidate = Self.appendQuery(query, to: hostPrefixed)
        if includesHostInTemplate, !hostCandidate.isEmpty {
            results.append(hostCandidate)
        }

        let pathCandidate = Self.appendQuery(query, to: pathOnly)
        if !pathCandidate.isEmpty || !results.contains(pathCandidate) {
            if !results.contains(pathCandidate) {
                results.append(pathCandidate)
            }
        }

        if includesHostInTemplate, pathOnly.isEmpty, !hostOnly.isEmpty {
            let hostOnlyCandidate = Self.appendQuery(query, to: hostOnly)
            if !hostOnlyCandidate.isEmpty, !results.contains(hostOnlyCandidate) {
                results.append(hostOnlyCandidate)
            }
        }

        if results.isEmpty {
            if let query, !query.isEmpty {
                results.append("?\(query)")
            } else {
                results.append("")
            }
        }

        return results
    }

    private static func normalizedComponents(for url: URL) -> URLComponents? {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }
        let sortedItems = (components.queryItems ?? []).sorted { $0.name < $1.name }
        components.queryItems = sortedItems.isEmpty ? nil : sortedItems
        components.fragment = nil
        return components
    }

    private static func hostPrefixedPath(from components: URLComponents) -> String {
        let host = components.host ?? ""
        let trimmed = trimmedPath(from: components)
        if host.isEmpty { return trimmed }
        if trimmed.isEmpty { return host }
        return "\(host)/\(trimmed)"
    }

    private static func trimmedPath(from components: URLComponents) -> String {
        components.percentEncodedPath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }

    private static func appendQuery(_ query: String?, to base: String) -> String {
        guard let query, !query.isEmpty else { return base }
        if base.isEmpty {
            return "?\(query)"
        }
        return "\(base)?\(query)"
    }

    private static func decomposeHostAndPath(from rawPath: String) -> (host: String?, path: String) {
        guard !rawPath.isEmpty else { return (nil, "") }
        if rawPath.hasPrefix("/") {
            let trimmed = rawPath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            return (nil, trimmed)
        }

        let segments = rawPath.split(separator: "/", omittingEmptySubsequences: false)
        guard let first = segments.first else { return (nil, "") }
        if segments.count == 1 {
            return (String(first), "")
        }
        let remaining = segments.dropFirst().map(String.init).joined(separator: "/")
        return (String(first), remaining)
    }
}

private extension Optional where Wrapped == String {
    var nonEmpty: String? {
        guard let value = self, !value.isEmpty else { return nil }
        return value
    }
}

private extension SchemeMapper {
    static func caseInsensitiveEqual(_ lhs: String, _ rhs: String) -> Bool {
        lhs.caseInsensitiveCompare(rhs) == .orderedSame
    }
}
