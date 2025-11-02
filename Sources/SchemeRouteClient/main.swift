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

    @SchemePattern("search?query=${query}&filter=${filter}")
    case search(query: String, filter: String?)

    @SchemePattern("user/${id}/posts?page=${page}&premium=${premium}")
    case userPosts(id: Int, page: Int, premium: Bool)

    @SchemePattern("product/${productId}?discount=${discount}&quantity=${quantity}")
    case product(productId: String, discount: Double?, quantity: Int?)
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

print("\n=== 옵셔널 쿼리 파라미터 테스트 ===")
printMatch("search?query=swift", as: DemoRoute.self)
printMatch("search?query=swift&filter=", as: DemoRoute.self)
printMatch("search?query=swift&filter=recent", as: DemoRoute.self)
verifyURL("myapp://app/search?query=swift", equals: DemoRoute.search(query: "swift", filter: nil))
verifyURL("myapp://app/search?query=swift&filter=", equals: DemoRoute.search(query: "swift", filter: nil))
verifyURL("myapp://app/search?query=swift&filter=recent", equals: DemoRoute.search(query: "swift", filter: "recent"))

if let searchURL = DemoRoute.search(query: "swift", filter: nil).url() {
    print("route -> URL: search(query: swift, filter: nil) => \(searchURL.absoluteString)")
} else {
    printWarning("route -> URL: search(query: swift, filter: nil) 생성 실패")
}

if let searchURL = DemoRoute.search(query: "swift", filter: "recent").url() {
    print("route -> URL: search(query: swift, filter: recent) => \(searchURL.absoluteString)")
} else {
    printWarning("route -> URL: search(query: swift, filter: recent) 생성 실패")
}

print("\n=== LosslessStringConvertible 타입 테스트 ===")
printMatch("user/123/posts?page=2&premium=true", as: DemoRoute.self)
printMatch("user/123/posts?page=2&premium=false", as: DemoRoute.self)
printMatch("user/abc/posts?page=2&premium=true", as: DemoRoute.self)
printURL("myapp://app/user/456/posts?page=3&premium=true", as: DemoRoute.self)
printURL("myapp://app/user/456/posts?page=abc&premium=true", as: DemoRoute.self)
verifyURL("myapp://app/user/123/posts?page=2&premium=true", equals: DemoRoute.userPosts(id: 123, page: 2, premium: true))
verifyURL("myapp://app/user/123/posts?page=2&premium=false", equals: DemoRoute.userPosts(id: 123, page: 2, premium: false))

if let postsURL = DemoRoute.userPosts(id: 999, page: 5, premium: true).url() {
    print("route -> URL: userPosts => \(postsURL.absoluteString)")
} else {
    printWarning("route -> URL: userPosts 생성 실패")
}

print("\n=== 옵셔널 타입 변환 테스트 ===")
printMatch("product/ABC123?discount=0.15&quantity=10", as: DemoRoute.self)
printMatch("product/ABC123?discount=0.15&quantity=", as: DemoRoute.self)
printMatch("product/ABC123?discount=&quantity=10", as: DemoRoute.self)
printMatch("product/ABC123", as: DemoRoute.self)
verifyURL("myapp://app/product/XYZ?discount=0.25&quantity=5", equals: DemoRoute.product(productId: "XYZ", discount: 0.25, quantity: 5))
verifyURL("myapp://app/product/XYZ?discount=0.25", equals: DemoRoute.product(productId: "XYZ", discount: 0.25, quantity: nil))
verifyURL("myapp://app/product/XYZ", equals: DemoRoute.product(productId: "XYZ", discount: nil, quantity: nil))

if let productURL1 = DemoRoute.product(productId: "TEST", discount: 0.5, quantity: 100).url() {
    print("route -> URL: product(discount: 0.5, quantity: 100) => \(productURL1.absoluteString)")
} else {
    printWarning("route -> URL: product 생성 실패")
}

if let productURL2 = DemoRoute.product(productId: "TEST", discount: nil, quantity: nil).url() {
    print("route -> URL: product(discount: nil, quantity: nil) => \(productURL2.absoluteString)")
} else {
    printWarning("route -> URL: product 생성 실패")
}

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
