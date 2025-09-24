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

    public init(patterns: [Pattern]) {
        self.patterns = patterns
    }

    public convenience init(_ configure: (inout Builder) -> Void) {
        var builder = Builder()
        configure(&builder)
        self.init(patterns: builder.patterns)
    }

    public func route(from rawValue: String) -> Route? {
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
        let normalized = Self.normalize(url: url)
        return route(from: normalized)
    }

    public func rawValue(for route: Route) -> String? {
        for pattern in patterns {
            guard let params = pattern.parameters(route) else { continue }
            guard let rendered = pattern.matcher.render(params: params) else { continue }
            return Self.join(path: rendered.path, queryItems: rendered.query)
        }
        return nil
    }

    public func url(for route: Route, scheme: String, host: String) -> URL? {
        guard let rawValue = rawValue(for: route) else { return nil }
        var components = URLComponents()
        components.scheme = scheme
        components.host = host

        let parts = rawValue.split(separator: "?", maxSplits: 1, omittingEmptySubsequences: false).map(String.init)
        if let path = parts.first {
            components.path = path.isEmpty ? "/" : "/" + path
        }
        if parts.count > 1 {
            components.percentEncodedQuery = parts[1]
        }
        return components.url
    }

    public static func normalize(url: URL) -> String {
        let trimmedPath = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let sortedItems = (components?.queryItems ?? []).sorted { $0.name < $1.name }
        components?.queryItems = sortedItems.isEmpty ? nil : sortedItems
        let query = components?.percentEncodedQuery
        if let query, !query.isEmpty {
            return trimmedPath.isEmpty ? "?\(query)" : "\(trimmedPath)?\(query)"
        } else {
            return trimmedPath
        }
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
}
