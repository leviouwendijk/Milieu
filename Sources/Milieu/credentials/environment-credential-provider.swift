import Foundation

/// Reads only explicitly mapped variables from a captured environment.
public struct EnvironmentCredentialProvider: CredentialProvider {
    private let symbols: [CredentialReference: String]
    private let environment: [String: String]

    public init(
        symbols: [CredentialReference: String],
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) {
        self.symbols = symbols
        self.environment = environment
    }

    public func resolve(_ reference: CredentialReference) async throws -> CredentialMaterial {
        guard let symbol = symbols[reference], let value = environment[symbol], !value.isEmpty else {
            throw CredentialError.missing(reference.id)
        }
        return CredentialMaterial(Data(value.utf8))
    }
}
