import Foundation

/// 스킴 기반 라우트가 채택할 공통 프로토콜
public protocol SchemeRoute: RawRepresentable where RawValue == String {
    /// 해당 라우트를 파싱/생성하기 위한 매퍼
    static var router: SchemeMapper<Self> { get }

    /// 라우트 전용 기본 스킴 (없으면 빈 문자열)
    static var scheme: String { get }

    /// 라우트 전용 기본 호스트 (없으면 빈 문자열)
    static var host: String { get }
}

public extension SchemeRoute {
    static var scheme: String { "" }
    static var host: String { "" }

    /// 기본 문자열(rawValue) → 라우트 변환 기본 구현
    init?(rawValue: String) {
        guard let route = Self.router.route(from: rawValue) else { return nil }
        self = route
    }

    /// URL → 라우트 변환 기본 구현 (nil 입력 시 실패)
    init?(url: URL?) {
        guard let url, let route = Self.router.route(from: url) else { return nil }
        self = route
    }

    /// 라우트를 정규화 문자열로 변환
    var rawValue: String {
        guard let value = Self.router.rawValue(for: self) else {
            assertionFailure("라우트 문자열 렌더링에 실패했습니다: \(self)")
            return ""
        }
        return value
    }

    /// 라우트를 URL 로 변환 (스킴/호스트는 상황에 맞게 지정)
    func url(scheme: String? = nil, host: String? = nil) -> URL? {
        let resolvedScheme = scheme ?? (Self.scheme.isEmpty ? nil : Self.scheme)
        let resolvedHost = host ?? (Self.host.isEmpty ? nil : Self.host)
        return Self.router.url(for: self, scheme: resolvedScheme, host: resolvedHost)
    }
}
