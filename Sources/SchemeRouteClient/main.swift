import Foundation
import SchemeRoute

@SchemeRoutable
enum DemoRoute: SchemeRoute, Equatable {
    @SchemePattern("")
    case home

    @SchemePattern("user/${id}/profile")
    case userProfile(id: String)

    @SchemePattern("article/${slug}")
    case article(slug: String)

    @SchemePattern("pay/complete?order_id=${orderId}")
    case payComplete(orderId: String)
}

func printMatch(_ rawValue: String) {
    if let route = DemoRoute(rawValue: rawValue) {
        print("rawValue -> route: \(rawValue) => \(route)")
    } else {
        print("rawValue -> route: \(rawValue) 매칭 실패")
    }
}

func printURL(_ urlString: String) {
    guard let url = URL(string: urlString) else { return }
    if let route = DemoRoute(url: url) {
        print("URL -> route: \(url.absoluteString) => \(route)")
    } else {
        print("URL -> route: \(url.absoluteString) 매칭 실패")
    }
}

func verifyURL(_ urlString: String, equals expected: DemoRoute) {
    guard let url = URL(string: urlString) else {
        print("URL 검증 실패: 잘못된 문자열 - \(urlString)")
        return
    }
    if let route = DemoRoute(url: url) {
        let result = route == expected ? "성공" : "실패"
        print("URL -> route 검증 (\(urlString)) => \(result) — 생성된 값: \(route)")
    } else {
        print("URL -> route 검증 (\(urlString)) => 실패 — 라우트를 만들 수 없습니다")
    }
}

print("=== DemoRoute.router 예시 ===")
printMatch("")
printMatch("user/42/profile")
printMatch("article/swift-macros")
printMatch("pay/complete?order_id=XYZ123")

if let url = DemoRoute.payComplete(orderId: "XYZ123").url() {
    print("route -> URL: payComplete => \(url.absoluteString)")
}

printURL("myapp://app/user/42/profile")
printURL("myapp://app/pay/complete?order_id=XYZ123")

verifyURL("myapp://app/user/42/profile", equals: .userProfile(id: "42"))
verifyURL("myapp://app/pay/complete?order_id=XYZ123", equals: .payComplete(orderId: "XYZ123"))
