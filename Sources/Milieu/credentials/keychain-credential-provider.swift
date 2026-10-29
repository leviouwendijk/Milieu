#if os(macOS) && canImport(Security)
import Foundation
import Security

/// The invoking signed process must possess the required Keychain access rights.
/// This backend does not authenticate clients; use it only in a trusted process.
public actor KeychainCredentialProvider: CredentialProvider {
    private let service: String
    private let accessGroup: String?
    private let synchronizable: Bool

    public init(service: String, accessGroup: String? = nil, synchronizable: Bool = false) {
        self.service = service
        self.accessGroup = accessGroup
        self.synchronizable = synchronizable
    }

    private func query(_ reference: CredentialReference) -> [String: Any] {
        var result: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: reference.id,
            kSecUseDataProtectionKeychain as String: true,
            kSecAttrSynchronizable as String: synchronizable
        ]
        if let accessGroup { result[kSecAttrAccessGroup as String] = accessGroup }
        return result
    }

    public func resolve(_ reference: CredentialReference) async throws -> CredentialMaterial {
        var attributes = query(reference)
        attributes[kSecReturnData as String] = true
        attributes[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        let status = SecItemCopyMatching(attributes as CFDictionary, &item)
        guard status == errSecSuccess else {
            if status == errSecItemNotFound { throw CredentialError.missing(reference.id) }
            throw CredentialError.keychain(OSStatusCode(status))
        }
        guard let data = item as? Data else {
            throw CredentialError.invalidEncoding
        }
        return CredentialMaterial(data)
    }

    public func store(_ material: CredentialMaterial, for reference: CredentialReference) throws {
        let attributes = query(reference)
        let update = [kSecValueData as String: material.data]
        let status = SecItemUpdate(attributes as CFDictionary, update as CFDictionary)
        if status == errSecItemNotFound {
            var addition = attributes
            addition[kSecValueData as String] = material.data
            addition[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlocked
            let added = SecItemAdd(addition as CFDictionary, nil)
            guard added == errSecSuccess else { throw CredentialError.keychain(OSStatusCode(added)) }
        } else if status != errSecSuccess {
            throw CredentialError.keychain(OSStatusCode(status))
        }
    }

    public func remove(_ reference: CredentialReference) throws {
        let status = SecItemDelete(query(reference) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw CredentialError.keychain(OSStatusCode(status))
        }
    }
}
#endif
