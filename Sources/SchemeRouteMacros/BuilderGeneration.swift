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
        if allBindings.count == 1 {
            let binding = allBindings[0]
            lines.append("    guard let \(binding.parameter.name) = params[\(binding.dictionaryKey.stringLiteral)] else { return nil }")
        } else {
            lines.append("    guard")
            for (index, binding) in allBindings.enumerated() {
                let suffix = index == allBindings.count - 1 ? "" : ","
                lines.append("        let \(binding.parameter.name) = params[\(binding.dictionaryKey.stringLiteral)]\(suffix)")
            }
            lines.append("    else { return nil }")
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

    let dictionaryEntries = (info.pathBindings.map { "\($0.dictionaryKey.stringLiteral): \($0.parameter.name)" } +
                             info.queryBindings.map { "\($0.dictionaryKey.stringLiteral): \($0.parameter.name)" })

    if dictionaryEntries.isEmpty {
        lines.append("    return [:]")
    } else {
        let joined = dictionaryEntries.joined(separator: ", ")
        lines.append("    return [\(joined)]")
    }

    lines.append("}")

    return lines.joined(separator: "\n")
}
