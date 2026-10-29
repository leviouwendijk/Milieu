import Foundation

public struct CredentialAccess: Hashable, Sendable {
    public let reference: CredentialReference
    public let consumer: String
    public let operation: String

    public init(reference: CredentialReference, consumer: String, operation: String) {
        self.reference = reference
        self.consumer = consumer
        self.operation = operation
    }
}

public struct CredentialAuditEvent: Sendable {
    public enum Decision: Sendable { case allowed, denied, failed }
    public let access: CredentialAccess
    public let decision: Decision
    public let timestamp: Date
}

/// In-process trusted component only. Caller identity is NOT authenticated here.
/// The future XPC adapter must derive authenticated identity from the OS before
/// authorizing requests; never accept an identity string supplied by a client.
public actor CredentialService {
    private let provider: any CredentialProvider
    private let grants: Set<CredentialAccess>
    private var events: [CredentialAuditEvent] = []

    public init(provider: any CredentialProvider, grants: Set<CredentialAccess>) {
        self.provider = provider
        self.grants = grants
    }

    /// Only trusted host/gateway code may call this method. Do not model-face it.
    public func resolve(_ access: CredentialAccess) async throws -> CredentialMaterial {
        guard grants.contains(access) else {
            events.append(.init(access: access, decision: .denied, timestamp: Date()))
            throw CredentialError.denied
        }
        do {
            let material = try await provider.resolve(access.reference)
            events.append(.init(access: access, decision: .allowed, timestamp: Date()))
            return material
        } catch {
            events.append(.init(access: access, decision: .failed, timestamp: Date()))
            throw error
        }
    }

    public func auditEvents() -> [CredentialAuditEvent] { events }
}
