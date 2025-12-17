import Foundation

/// How to combine explicit replacements with other sources.
public enum EnvironmentExpansionPolicy: Sendable, Equatable {
    /// Only use explicit `.replacements`; unknown tokens are left *as-is* (no fallback).
    case strict
    /// Use `.replacements` first, then fallback to provided dictionary (e.g. file vars), then process env.
    case permissive(fileEnv: [String: String] = [:], processEnv: [String: String] = ProcessInfo.processInfo.environment)
}
