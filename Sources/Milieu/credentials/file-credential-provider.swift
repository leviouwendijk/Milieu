import Foundation
import Readers

/// Explicit trusted reference-to-URL mapping, not arbitrary caller-supplied paths.
public struct FileCredentialProvider: CredentialProvider {
    private let files: [CredentialReference: URL]

    public init(files: [CredentialReference: URL]) {
        self.files = files
    }

    public func resolve(_ reference: CredentialReference) async throws -> CredentialMaterial {
        guard let url = files[reference], url.isFileURL else {
            throw CredentialError.missing(reference.id)
        }
        return try CredentialMaterial(DataFileReader(url).read().data)
    }
}
