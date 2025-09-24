# SchemeRoute
SchemeRoute

[![Swift Version](https://img.shields.io/endpoint?url=https://swiftpackageindex.com/api/packages/ShapeKim98/SchemeRoute/badge?type=swift-versions)](https://swiftpackageindex.com/ShapeKim98/SchemeRoute)
[![Platform Support](https://img.shields.io/endpoint?url=https://swiftpackageindex.com/api/packages/ShapeKim98/SchemeRoute/badge?type=platforms)](https://swiftpackageindex.com/ShapeKim98/SchemeRoute)

Swift 매크로를 이용해 URL 스킴 기반 라우팅 코드를 자동으로 생성하는 패키지입니다.<br>
This package uses Swift macros to generate URL scheme based routing code automatically.
`enum` 선언과 패턴만으로 문자열/URL ↔ 라우트 변환을 위한 `SchemeMapper` 를 생성할 수 있습니다.<br>
With just an `enum` declaration and patterns, you can build a `SchemeMapper` for string/URL ↔ route conversions.

## 요구 사항
Requirements

- Swift 5.10 이상 (매크로 기능 활용)<br>
  Swift 5.10 or later (requires macro support)
- iOS 13 / macOS 10.15 / tvOS 13 / watchOS 6 / macCatalyst 13 이상 타깃<br>
  Targets iOS 13 / macOS 10.15 / tvOS 13 / watchOS 6 / macCatalyst 13 or newer

## 설치 (Swift Package Manager)
Installation (Swift Package Manager)

`Package.swift` 의 `dependencies` 배열에 `SchemeRoute` 를 최신 버전으로 추가합니다 (현재 0.1.0).<br>
Add `SchemeRoute` to the `dependencies` array in `Package.swift` with the latest version (currently 0.1.0).

```swift
.package(url: "https://github.com/ShapeKim98/SchemeRoute.git", from: "0.1.0")
```

사용할 타깃의 `dependencies` 에 `SchemeRoute` 를 명시합니다.<br>
Declare `SchemeRoute` in the target's `dependencies` where it will be used.

```swift
.target(
    name: "YourApp",
    dependencies: [
        .product(name: "SchemeRoute", package: "SchemeRoute")
    ]
)
```

Xcode에서는 **File > Add Packages...** 메뉴에서 같은 URL을 입력하면 됩니다.<br>
In Xcode, use **File > Add Packages...** and enter the same URL.

## 빠른 시작
Quick Start

```swift
import SchemeRoute

@SchemeRoutable
enum AppRoute: SchemeRoute, Equatable {
    @SchemePattern("")
    case home

    @SchemePattern("user/${id}/profile")
    case userProfile(id: String)

    @SchemePattern("article/${slug}?ref=${ref}")
    case article(slug: String, ref: String)
}

// 문자열 → 라우트
let route = AppRoute(rawValue: "user/42/profile")
// URL → 라우트
let fromURL = AppRoute(url: URL(string: "myapp://app/article/swift?ref=newsletter"))
// 라우트 → URL
let url = AppRoute.article(slug: "swift", ref: "newsletter").url(scheme: "myapp", host: "app")
```

`@SchemeRoutable` 매크로는 `enum` 내 모든 케이스를 스캔하여 `SchemeMapper<AppRoute>` 를 생성합니다.<br>
The `@SchemeRoutable` macro scans every case in the `enum` and generates a `SchemeMapper<AppRoute>`.
`init?(url:)` 은 옵셔널 URL을 그대로 받아 nil 이면 초기화에 실패합니다.<br>
`init?(url:)` accepts an optional URL and returns `nil` when the argument is `nil`.
`SchemeRoute` 프로토콜의 기본 구현(`rawValue`, `init?(rawValue:)`, `init?(url:)`)도 자동으로 동작합니다.<br>
The default `SchemeRoute` implementations (`rawValue`, `init?(rawValue:)`, `init?(url:)`) then work automatically.

## 패턴 작성 규칙
Pattern Rules

- 패턴 문자열은 `path?query` 형태이며, 쿼리 문자열은 선택입니다.<br>
  Pattern strings follow `path?query`, and the query component is optional.
- 경로와 쿼리에서 값이 되는 부분은 `${name}` 플레이스홀더로 표기합니다.<br>
  Use `${name}` placeholders wherever the path or query should inject values.
    - 경로 예: `user/${id}/profile`<br>
      Path example: `user/${id}/profile`
    - 쿼리 예: `pay/complete?order_id=${orderId}`<br>
      Query example: `pay/complete?order_id=${orderId}`
- 플레이스홀더 이름은 `case` 의 연관값 라벨과 1:1 로 매칭되어야 하며, 모든 연관값은 `String` 타입이어야 합니다.<br>
  Placeholder names must match associated value labels 1:1, and every associated value must be `String`.
- 같은 연관값을 두 번 이상 사용할 수 없고 사용하지 않은 연관값이 있으면 오류가 발생합니다.<br>
  The same associated value cannot be used more than once, and unused associated values trigger an error.
- 외부 라벨이 붙은 연관값(`case article(slug slug: String)`)은 지원하지 않습니다.<br>
  Associated values with external labels (e.g. `case article(slug slug: String)`) are not supported.

## 수동 라우터 구성
Manual Router Configuration

매크로 대신 직접 매퍼를 구성하려면 `SchemeMapper` 의 `Builder` 를 사용할 수 있습니다.<br>
If you prefer manual control, build the mapper by hand with `SchemeMapper`'s `Builder`.

```swift
let router = SchemeMapper<AppRoute> { builder in
    builder.register("user/${id}/profile", queryKeys: []) { params in
        guard let id = params["id"] else { return nil }
        return .userProfile(id: id)
    } render: { route in
        guard case let .userProfile(id) = route else { return nil }
        return ["id": id]
    }
}
```

대부분의 경우 매크로를 사용하는 편이 선언적이며 오류를 줄일 수 있습니다.<br>
In most cases, macros remain more declarative and help prevent mistakes.

## 예제 실행
Example Run

리포지토리에는 간단한 실행 예제가 포함되어 있습니다.<br>
A simple runnable example ships with the repository.

```bash
swift run SchemeRouteClient
```

출력 로그를 통해 문자열/URL 매칭과 URL 생성을 확인할 수 있습니다.<br>
Check the output log to see string/URL matching and URL generation in action.

## 라이선스
License

이 프로젝트는 [MIT License](LICENSE) 하에 배포됩니다.<br>
This project is distributed under the [MIT License](LICENSE).
