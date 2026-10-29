import Foundation

public protocol CredentialProvider: Sendable {
    func resolve(_ reference: CredentialReference) async throws -> CredentialMaterial
}

/// Routing is explicit: a missing reference never falls back to a different backend.
public struct RoutedCredentialProvider: CredentialProvider {
    private let routes: [CredentialReference: any CredentialProvider]

    public init(routes: [CredentialReference: any CredentialProvider]) {
        self.routes = routes
    }

    public func resolve(_ reference: CredentialReference) async throws -> CredentialMaterial {
        guard let provider = routes[reference] else {
            throw CredentialError.missing(reference.id)
        }
        return try await provider.resolve(reference)
    }
}
