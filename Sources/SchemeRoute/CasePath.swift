/// 간단한 CasePath 구현 (Swift CasePath 의존 없이 사용)
public struct CasePath<Root, Value> {
    public let embed: (Value) -> Root
    public let extract: (Root) -> Value?

    public init(embed: @escaping (Value) -> Root, extract: @escaping (Root) -> Value?) {
        self.embed = embed
        self.extract = extract
    }
}
