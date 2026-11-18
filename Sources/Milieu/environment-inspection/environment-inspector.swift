import Foundation
import Readers

public enum EnvironmentPresence: String, Sendable, Codable {
    case set
    case empty
    case missing
}

/// A trusted .env file whose names may be reported. Hosts choose these;
/// callers never supply paths, or the inspector becomes a probe of any file.
public struct EnvironmentDeclarationSource: Hashable, Sendable {
    /// What a report shows instead of the path, such as `$DEV_ENV`.
    public let label: String
    public let url: URL

    public init(label: String, url: URL) {
        self.label = label
        self.url = url
    }
}

public struct EnvironmentDeclaration: Hashable, Sendable {
    public let name: String
    public let source: EnvironmentDeclarationSource
    public let line: Int
    public let isEmpty: Bool
    /// Whether the declared value equals this process's value; nil when the
    /// process lacks the name. Neither value leaves Milieu.
    public let matchesProcess: Bool?
}

/// A parsed declaration source. Holds values only to compare them.
public struct EnvironmentDeclarationFile: Sendable {
    public let source: EnvironmentDeclarationSource
    fileprivate let entries: [String: DotEnvEntry]

    public init(_ source: EnvironmentDeclarationSource) throws {
        self.source = source
        let text = try TextFileReader(source.url).read().text
        entries = Dictionary(
            uniqueKeysWithValues: try DotEnvParser.entries(text).map { ($0.name, $0) }
        )
    }

    public var names: [String] { entries.keys.sorted() }
}

/// Answers questions about environment names without returning values.
public struct EnvironmentInspector: Sendable {
    private let environment: [String: String]

    public init(environment: [String: String] = ProcessInfo.processInfo.environment) {
        self.environment = environment
    }

    public func presence(_ name: String) -> EnvironmentPresence {
        guard let value = environment[name] else { return .missing }
        return value.isEmpty ? .empty : .set
    }

    /// Close names from this process and `declared`, never `name` itself.
    /// Bounded and near-only, so it cannot list the environment.
    public func suggestions(
        for name: String,
        among declared: [String] = [],
        limit: Int = 3
    ) -> [String] {
        SymbolSimilarity.closest(
            to: name,
            in: Set(environment.keys).union(declared),
            limit: min(max(limit, 1), 5)
        )
    }

    public func declaration(
        of name: String,
        in file: EnvironmentDeclarationFile
    ) -> EnvironmentDeclaration? {
        guard let entry = file.entries[name] else { return nil }
        return .init(
            name: name,
            source: file.source,
            line: entry.line,
            isEmpty: entry.value.isEmpty,
            matchesProcess: environment[name].map { $0 == entry.value }
        )
    }
}
