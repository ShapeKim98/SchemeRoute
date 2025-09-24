import Foundation

/// 경로 및 쿼리 매칭을 위한 패턴 객체
public struct PathPattern {
    private enum Segment {
        case literal(String)
        case parameter(String)
    }

    public let template: String
    public let queryKeys: [String]

    private let segments: [Segment]

    public init(template: String, queryKeys: [String]) {
        let normalizedTemplate = PathPattern.normalizePlaceholders(in: template)
        self.template = normalizedTemplate
        self.queryKeys = queryKeys
        self.segments = PathPattern.parseSegments(from: normalizedTemplate)
    }

    /// path 와 query 가 패턴에 매칭되는 경우 파라미터 딕셔너리를 반환
    public func match(path: String, query: [String: String]) -> [String: String]? {
        let pathParts = path.split(separator: "/").map(String.init)
        guard pathParts.count == segments.count else { return nil }

        var params: [String: String] = [:]
        for (part, segment) in zip(pathParts, segments) {
            switch segment {
            case let .literal(value):
                if value != part { return nil }
            case let .parameter(key):
                params[key] = part
            }
        }

        for key in queryKeys {
            guard let value = query[key], !value.isEmpty else { return nil }
            params[key] = value
        }
        return params
    }

    /// 파라미터로부터 실제 path & query 를 생성
    public func render(params: [String: String]) -> (path: String, query: [URLQueryItem])? {
        var renderedSegments: [String] = []
        renderedSegments.reserveCapacity(segments.count)

        for segment in segments {
            switch segment {
            case let .literal(value):
                renderedSegments.append(value)
            case let .parameter(key):
                guard let value = params[key] else { return nil }
                renderedSegments.append(value)
            }
        }

        let path = renderedSegments.joined(separator: "/")
        let queryItems: [URLQueryItem] = queryKeys.compactMap { key in
            guard let value = params[key] else { return nil }
            return URLQueryItem(name: key, value: value)
        }
        if queryItems.count != queryKeys.count { return nil }
        return (path, queryItems)
    }

    private static func normalizePlaceholders(in template: String) -> String {
        guard !template.isEmpty else { return template }
        let segments = template.split(separator: "/").map { rawSegment -> String in
            let segment = String(rawSegment)
            if let colonName = placeholderNameFromColon(segment) {
                return "${\(colonName)}"
            }
            return segment
        }
        return segments.joined(separator: "/")
    }

    private static func parseSegments(from template: String) -> [Segment] {
        guard !template.isEmpty else { return [] }
        return template.split(separator: "/").map { rawSegment -> Segment in
            let segment = String(rawSegment)
            if let name = placeholderName(in: segment) {
                return .parameter(name)
            }
            return .literal(segment)
        }
    }

    private static func placeholderName(in segment: String) -> String? {
        guard segment.hasPrefix("${"), segment.hasSuffix("}"), segment.count > 3 else { return nil }
        let start = segment.index(segment.startIndex, offsetBy: 2)
        let end = segment.index(before: segment.endIndex)
        let name = segment[start..<end]
        return name.isEmpty ? nil : String(name)
    }

    private static func placeholderNameFromColon(_ segment: String) -> String? {
        guard segment.hasPrefix(":"), segment.count > 1 else { return nil }
        let name = segment.dropFirst()
        return name.isEmpty ? nil : String(name)
    }
}
