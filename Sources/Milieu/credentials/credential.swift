import Foundation

public struct CredentialReference: Hashable, Codable, Sendable {
    public let id: String

    public init(_ id: String) {
        self.id = id
    }
}

public struct CredentialMaterial: Sendable, CustomStringConvertible {
    public let data: Data

    public init(_ data: Data) {
        self.data = data
    }

    public func utf8() throws -> String {
        guard let value = String(data: data, encoding: .utf8) else {
            throw CredentialError.invalidEncoding
        }
        return value
    }

    public var description: String { "<redacted credential>" }
}

public enum CredentialError: Error, LocalizedError, Sendable {
    case missing(String)
    case invalidConfiguration(String)
    case invalidEncoding
    case denied
    case keychain(OSStatusCode)

    public var errorDescription: String? {
        switch self {
        case .missing(let id): return "Credential is unavailable: \(id)"
        case .invalidConfiguration(let reason): return "Invalid credential configuration: \(reason)"
        case .invalidEncoding: return "Credential cannot be decoded as UTF-8"
        case .denied: return "Credential access denied"
        case .keychain(let status): return "Keychain operation failed (status \(status.rawValue))"
        }
    }
}

public struct OSStatusCode: Hashable, Sendable {
    public let rawValue: Int32
    public init(_ rawValue: Int32) { self.rawValue = rawValue }
}
