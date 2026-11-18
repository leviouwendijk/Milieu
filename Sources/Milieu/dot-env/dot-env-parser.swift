import Foundation

/// One `NAME=value` line of a .env file. Values stay inside Milieu.
struct DotEnvEntry: Sendable {
    let name: String
    let line: Int
    let value: String
}

/// Strict literal .env parsing. Never evaluates shell syntax or expands variables.
enum DotEnvParser {
    static func entries(_ text: String) throws -> [DotEnvEntry] {
        var entries: [DotEnvEntry] = []
        var seen: Set<String> = []

        for (index, line) in text.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline).enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("#") { continue }
            let declaration = trimmed.hasPrefix("export ") ? String(trimmed.dropFirst(7)) : trimmed
            guard let separator = declaration.firstIndex(of: "=") else {
                throw CredentialError.invalidConfiguration("Invalid .env entry at line \(index + 1)")
            }
            let name = declaration[..<separator].trimmingCharacters(in: .whitespaces)
            guard !name.isEmpty, seen.insert(name).inserted else {
                throw CredentialError.invalidConfiguration("Duplicate or empty .env name at line \(index + 1)")
            }
            var value = String(declaration[declaration.index(after: separator)...]).trimmingCharacters(in: .whitespaces)
            if value.hasPrefix("\"") || value.hasPrefix("'") {
                guard let quote = value.first, value.count >= 2, value.last == quote else {
                    throw CredentialError.invalidConfiguration("Unclosed .env quote at line \(index + 1)")
                }
                value = String(value.dropFirst().dropLast())
            }
            entries.append(.init(name: name, line: index + 1, value: value))
        }
        return entries
    }
}
