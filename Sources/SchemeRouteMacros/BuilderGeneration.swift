private func encodeBinding(_ binding: CaseInfo.Binding) -> String {
    let key = binding.dictionaryKey.stringLiteral
    let param = binding.parameter

    if param.isString {
        // String 타입
        if param.isOptional {
            return "\(key): \(param.name) ?? \"\""
        } else {
            return "\(key): \(param.name)"
        }
    } else {
        // 기타 타입 (LosslessStringConvertible)
        if param.isOptional {
            return "\(key): \(param.name).map(String.init) ?? \"\""
        } else {
            return "\(key): String(\(param.name))"
        }
    }
}

func generateBuilderCall(for info: CaseInfo) -> String {
    if info.parameters.isEmpty {
        let pathLiteral = info.pathTemplate.stringLiteral
        // Avoid using the Equatable-based helper because RawRepresentable routes compare via rawValue and recurse.
        return """
        builder.register(\(pathLiteral), match: { _ in
            return .\(info.caseName)
        }) { route in
            guard case .\(info.caseName) = route else { return nil }
            return [:]
        }
        """
    }

    let pathLiteral = info.pathTemplate.stringLiteral
    let queryLiteral: String
    if info.queryKeys.isEmpty {
        queryLiteral = ""
    } else {
        let items = info.queryKeys.map { $0.stringLiteral }.joined(separator: ", ")
        queryLiteral = ", queryKeys: [\(items)]"
    }

    var lines: [String] = []
    lines.append("builder.register(\(pathLiteral)\(queryLiteral), match: { params in")

    let allBindings = info.pathBindings + info.queryBindings
    if !allBindings.isEmpty {
        let nonOptionalBindings = allBindings.filter { !$0.parameter.isOptional }
        let optionalBindings = allBindings.filter { $0.parameter.isOptional }

        // 비옵셔널 바인딩 처리
        if !nonOptionalBindings.isEmpty {
            if nonOptionalBindings.count == 1 {
                let binding = nonOptionalBindings[0]
                lines.append("    guard let __str_\(binding.parameter.name) = params[\(binding.dictionaryKey.stringLiteral)] else { return nil }")
                if binding.parameter.isString {
                    lines.append("    let \(binding.parameter.name) = __str_\(binding.parameter.name)")
                } else {
                    lines.append("    guard let \(binding.parameter.name) = \(binding.parameter.unwrappedType)(__str_\(binding.parameter.name)) else { return nil }")
                }
            } else {
                lines.append("    guard")
                for (index, binding) in nonOptionalBindings.enumerated() {
                    let suffix = index == nonOptionalBindings.count - 1 ? "" : ","
                    lines.append("        let __str_\(binding.parameter.name) = params[\(binding.dictionaryKey.stringLiteral)]\(suffix)")
                }
                lines.append("    else { return nil }")

                for binding in nonOptionalBindings {
                    if binding.parameter.isString {
                        lines.append("    let \(binding.parameter.name) = __str_\(binding.parameter.name)")
                    } else {
                        lines.append("    guard let \(binding.parameter.name) = \(binding.parameter.unwrappedType)(__str_\(binding.parameter.name)) else { return nil }")
                    }
                }
            }
        }

        // 옵셔널 바인딩 처리
        for binding in optionalBindings {
            if binding.parameter.unwrappedType == "String" {
                lines.append("    let \(binding.parameter.name) = params[\(binding.dictionaryKey.stringLiteral)].flatMap { $0.isEmpty ? nil : $0 }")
            } else {
                lines.append("    let \(binding.parameter.name) = params[\(binding.dictionaryKey.stringLiteral)].flatMap { $0.isEmpty ? nil : \(binding.parameter.unwrappedType)($0) }")
            }
        }
    }

    let arguments = info.parameters
        .map { parameter in "\(parameter.label): \(parameter.name)" }
        .joined(separator: ", ")
    lines.append("    return .\(info.caseName)(\(arguments))")
    lines.append("}) { route in")

    let patternArguments = info.parameters
        .map { "\($0.label): \($0.name)" }
        .joined(separator: ", ")
    lines.append("    guard case let .\(info.caseName)(\(patternArguments)) = route else { return nil }")

    let dictionaryEntries = (info.pathBindings.map { binding in
        encodeBinding(binding)
    } + info.queryBindings.map { binding in
        encodeBinding(binding)
    })

    if dictionaryEntries.isEmpty {
        lines.append("    return [:]")
    } else {
        let joined = dictionaryEntries.joined(separator: ", ")
        lines.append("    return [\(joined)]")
    }

    lines.append("}")

    return lines.joined(separator: "\n")
}
