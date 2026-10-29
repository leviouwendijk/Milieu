import Foundation

/// Strict literal .env reader. Never evaluates shell syntax or expands variables.
public struct DotEnvCredentialProvider: CredentialProvider {
    private let symbols: [CredentialReference: String]
    private let values: [String: String]

    public init(file: URL, symbols: [CredentialReference: String]) throws {
        self.symbols = symbols
        let text = try String(contentsOf: file, encoding: .utf8)
        var parsed: [String: String] = [:]

        for (index, line) in text.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline).enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("#") { continue }
            let declaration = trimmed.hasPrefix("export ") ? String(trimmed.dropFirst(7)) : trimmed
            guard let separator = declaration.firstIndex(of: "=") else {
                throw CredentialError.invalidConfiguration("Invalid .env entry at line \(index + 1)")
            }
            let name = declaration[..<separator].trimmingCharacters(in: .whitespaces)
            guard !name.isEmpty, parsed[name] == nil else {
                throw CredentialError.invalidConfiguration("Duplicate or empty .env name at line \(index + 1)")
            }
            var value = String(declaration[declaration.index(after: separator)...]).trimmingCharacters(in: .whitespaces)
            if value.hasPrefix("\"") || value.hasPrefix("'") {
                guard let quote = value.first, value.count >= 2, value.last == quote else {
                    throw CredentialError.invalidConfiguration("Unclosed .env quote at line \(index + 1)")
                }
                value = String(value.dropFirst().dropLast())
            }
            parsed[name] = value
        }
        values = parsed
    }

    public func resolve(_ reference: CredentialReference) async throws -> CredentialMaterial {
        guard let symbol = symbols[reference], let value = values[symbol], !value.isEmpty else {
            throw CredentialError.missing(reference.id)
        }
        return CredentialMaterial(Data(value.utf8))
    }
}
