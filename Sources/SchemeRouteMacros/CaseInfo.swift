import SwiftSyntax

struct CaseInfo {
    let caseName: String
    let pathTemplate: String
    let queryKeys: [String]
    let pathBindings: [Binding]
    let queryBindings: [Binding]
    let parameters: [Parameter]

    struct Binding {
        let dictionaryKey: String
        let parameter: Parameter
    }

    struct Parameter {
        let name: String
        let label: String
        let typeDescription: String
    }

    init(enumCaseElement element: EnumCaseElementSyntax, pattern: ParsedPattern) throws {
        caseName = element.name.text

        let parameters = try CaseInfo.parseParameters(from: element)
        self.parameters = parameters

        var bindingsByPlaceholder: [String: Parameter] = [:]
        for parameter in parameters {
            bindingsByPlaceholder[parameter.label] = parameter
        }

        var usedLabels = Set<String>()
        var pathBindings: [Binding] = []
        for placeholder in pattern.pathPlaceholders {
            guard let parameter = bindingsByPlaceholder[placeholder] else {
                throw SimpleError("플레이스홀더 \(placeholder) 와 일치하는 연관값을 찾을 수 없습니다.")
            }
            if usedLabels.contains(parameter.label) {
                throw SimpleError("연관값 \(parameter.label) 이 여러 플레이스홀더에 중복 매핑되었습니다.")
            }
            usedLabels.insert(parameter.label)
            pathBindings.append(Binding(dictionaryKey: placeholder, parameter: parameter))
        }

        var queryBindings: [Binding] = []
        for item in pattern.queryPlaceholders {
            guard let parameter = bindingsByPlaceholder[item.placeholder] else {
                throw SimpleError("플레이스홀더 \(item.placeholder) 와 일치하는 연관값을 찾을 수 없습니다.")
            }
            if usedLabels.contains(parameter.label) {
                throw SimpleError("연관값 \(parameter.label) 이 여러 플레이스홀더에 중복 매핑되었습니다.")
            }
            usedLabels.insert(parameter.label)
            queryBindings.append(Binding(dictionaryKey: item.key, parameter: parameter))
        }

        if !parameters.isEmpty && usedLabels.count != parameters.count {
            let unused = parameters.map { $0.label }.filter { !usedLabels.contains($0) }
            if let first = unused.first {
                throw SimpleError("연관값 \(first) 에 대응하는 플레이스홀더가 없습니다.")
            }
        }

        self.pathTemplate = pattern.pathTemplate
        self.pathBindings = pathBindings
        self.queryBindings = queryBindings
        self.queryKeys = queryBindings.map { $0.dictionaryKey }
    }

    private static func parseParameters(from element: EnumCaseElementSyntax) throws -> [Parameter] {
        guard let parameterClause = element.parameterClause else { return [] }
        var parameters: [Parameter] = []

        for parameter in parameterClause.parameters {
            if let second = parameter.secondName {
                throw SimpleError("연관값에는 외부 라벨을 사용할 수 없습니다. 'case sample(id: String)' 형식을 사용해 주세요. 현재: \(second.text)")
            }

            guard let labelToken = parameter.firstName else {
                throw SimpleError("연관값에는 라벨이 필요합니다. 예: case sample(id: String)")
            }
            let label = labelToken.text
            if label == "_" {
                throw SimpleError("연관값 라벨에 '_' 는 사용할 수 없습니다. 별도의 이름을 지정해 주세요.")
            }

            let typeDescription = parameter.type.trimmedDescription
            guard typeDescription == "String" else {
                throw SimpleError("연관값 \(label) 은 String 타입이어야 합니다. 현재 타입: \(typeDescription)")
            }

            parameters.append(Parameter(name: label, label: label, typeDescription: typeDescription))
        }

        return parameters
    }
}
