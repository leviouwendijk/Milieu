/// A single explicit replacement rule.
/// Examples:
///     .variable(key: "$THIS", replacement: .value("asdf"))
///     .variable(key: "$HOME", replacement: .home)
///     .variable(key: "$CWD", replacement: .cwd)
public enum EnvironmentReplacement: Sendable, Equatable {
    case variable(key: String, replacement: EnvironmentReplacementValue)

    public static let home = Self.variable(key: "$HOME", replacement: .home)
    public static let cwd = Self.variable(key: "$CWD", replacement: .cwd)
}
