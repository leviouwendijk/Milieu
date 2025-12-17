public enum EnvironmentReplacementValue: Sendable, Equatable {
    case value(String)                       
    case env(String)                         
    case home                       
    case cwd                    
}
