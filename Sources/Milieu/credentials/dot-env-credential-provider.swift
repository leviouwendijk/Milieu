import Foundation
import Readers

/// Strict literal .env reader. Never evaluates shell syntax or expands variables.
public struct DotEnvCredentialProvider: CredentialProvider {
    private let symbols: [CredentialReference: String]
    private let values: [String: String]

    public init(file: URL, symbols: [CredentialReference: String]) throws {
        self.symbols = symbols
        let text = try TextFileReader(file).read().text
        values = Dictionary(
            uniqueKeysWithValues: try DotEnvParser.entries(text).map { ($0.name, $0.value) }
        )
    }

    public func resolve(_ reference: CredentialReference) async throws -> CredentialMaterial {
        guard let symbol = symbols[reference], let value = values[symbol], !value.isEmpty else {
            throw CredentialError.missing(reference.id)
        }
        return CredentialMaterial(Data(value.utf8))
    }
}
