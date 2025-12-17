public protocol EnvironmentReplacing: Sendable {
    var replacements: [EnvironmentReplacement] { get }
    var policy: EnvironmentExpansionPolicy { get }
}
