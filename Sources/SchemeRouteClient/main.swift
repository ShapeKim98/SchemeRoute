import Foundation
import SchemeRoute

@SchemeRoutable
enum DemoRoute: Equatable {
    static var scheme: String { "myapp" }
    static var host: String { "app" }

    @SchemePattern("")
    case home

    @SchemePattern("user/${id}/profile")
    case userProfile(id: String)

    @SchemePattern("article/${slug}")
    case article(slug: String)

    @SchemePattern("pay/complete?order_id=${orderId}")
    case payComplete(orderId: String)
}

@SchemeRoutable
enum InlineRoute: Equatable {
    @SchemePattern("kakaolink?categoryId=${categoryId}")
    case kakaolink(categoryId: String)

    @SchemePattern("inline.app/user/${id}/profile")
    case inlineProfile(id: String)
}

func formatPrefix(_ base: String, label: String) -> String {
    label.isEmpty ? base : "\(base)[\(label)]"
}

func printMatch<Route: SchemeRoute>(_ rawValue: String, as routeType: Route.Type, label: String = "") {
    _ = routeType
    let display = rawValue.isEmpty ? "(empty)" : rawValue
    let prefix = formatPrefix("rawValue -> route", label: label)
    if let route = Route(rawValue: rawValue) {
        print("\(prefix): \(display) => \(route)")
    } else {
        printWarning("\(prefix): \(display) 매칭 실패")
    }
}

func printURL<Route: SchemeRoute>(_ urlString: String, as routeType: Route.Type, label: String = "") {
    _ = routeType
    let prefix = formatPrefix("URL -> route", label: label)
    guard let url = URL(string: urlString) else {
        printWarning("\(prefix): 잘못된 URL 문자열 - \(urlString)")
        return
    }
    if let route = Route(url: url) {
        print("\(prefix): \(url.absoluteString) => \(route)")
    } else {
        printWarning("\(prefix): \(url.absoluteString) 매칭 실패")
    }
}

func verifyURL<Route: SchemeRoute & Equatable>(_ urlString: String, equals expected: Route, label: String = "") {
    let prefix = formatPrefix("URL -> route 검증", label: label)
    guard let url = URL(string: urlString) else {
        printWarning("\(prefix): 잘못된 문자열 - \(urlString)")
        return
    }
    if let route = Route(url: url) {
        let isSuccess = route == expected
        let result = isSuccess ? "성공" : "실패"
        let message = "\(prefix) (\(urlString)) => \(result) — 생성된 값: \(route)"
        if isSuccess {
            print(message)
        } else {
            printWarning(message)
        }
    } else {
        printWarning("\(prefix) (\(urlString)) => 실패 — 라우트를 만들 수 없습니다")
    }
}

func printWarning(_ message: String) {
    print("[경고] \(message)")
}

print("=== DemoRoute.router 예시 ===")
printMatch("", as: DemoRoute.self)
printMatch("user/42/profile", as: DemoRoute.self)
printMatch("article/swift-macros", as: DemoRoute.self)
printMatch("pay/complete?order_id=XYZ123", as: DemoRoute.self)
printMatch("unknown/path", as: DemoRoute.self)

if let url = DemoRoute.payComplete(orderId: "XYZ123").url() {
    print("route -> URL: payComplete => \(url.absoluteString)")
} else {
    printWarning("route -> URL: payComplete 생성 실패")
}

printURL("myapp://app", as: DemoRoute.self)
printURL("myapp://app/user/42/profile", as: DemoRoute.self)
printURL("myapp://app/pay/complete?order_id=XYZ123", as: DemoRoute.self)
printURL("myapp://app/pay/complete", as: DemoRoute.self)
printURL("myapp://app/pay/complete?order_id=", as: DemoRoute.self)
printURL("not-a-url", as: DemoRoute.self)

verifyURL("myapp://app", equals: DemoRoute.home)
verifyURL("myapp://app/user/42/profile", equals: DemoRoute.userProfile(id: "42"))
verifyURL("myapp://app/pay/complete?order_id=XYZ123", equals: DemoRoute.payComplete(orderId: "XYZ123"))
verifyURL("myapp://app/pay/complete", equals: DemoRoute.payComplete(orderId: "XYZ123"))
verifyURL("myapp://app/pay/complete?order=XYZ123", equals: DemoRoute.payComplete(orderId: "XYZ123"))

print("\n=== InlineRoute 예시 (기본 스킴/호스트 없음) ===")
printMatch("kakaolink?categoryId=424", as: InlineRoute.self, label: "InlineRoute")
printMatch("inline.app/user/42/profile", as: InlineRoute.self, label: "InlineRoute")
printMatch("inline.app/unknown", as: InlineRoute.self, label: "InlineRoute")

if let kakaoURL = InlineRoute.kakaolink(categoryId: "424").url(scheme: "kakaoapp") {
    print("route -> URL[InlineRoute]: kakaolink => \(kakaoURL.absoluteString)")
} else {
    printWarning("route -> URL[InlineRoute]: kakaolink 생성 실패")
}

if let inlineURL = InlineRoute.inlineProfile(id: "42").url(scheme: "myapp") {
    print("route -> URL[InlineRoute]: inlineProfile => \(inlineURL.absoluteString)")
} else {
    printWarning("route -> URL[InlineRoute]: inlineProfile 생성 실패")
}

printURL("kakaoapp://kakaolink?categoryId=424", as: InlineRoute.self, label: "InlineRoute")
printURL("myapp://inline.app/user/42/profile", as: InlineRoute.self, label: "InlineRoute")
printURL("myapp://inline.app/user/42", as: InlineRoute.self, label: "InlineRoute")

verifyURL("kakaoapp://kakaolink?categoryId=424", equals: InlineRoute.kakaolink(categoryId: "424"), label: "InlineRoute")
verifyURL("myapp://inline.app/user/42/profile", equals: InlineRoute.inlineProfile(id: "42"), label: "InlineRoute")
