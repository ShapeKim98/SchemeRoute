import Foundation
import SchemeRoute

@SchemeRoutable
enum DemoRoute: SchemeRoute, Equatable {
    @RoutePattern("")
    case home

    @RoutePattern("user/${id}/profile")
    case userProfile(id: String)

    @RoutePattern("article/${slug}")
    case article(slug: String)

    @RoutePattern("pay/complete?order_id=${orderId}")
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
