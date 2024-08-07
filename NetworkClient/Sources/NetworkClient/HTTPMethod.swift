//

import Foundation

/// Enum representing the different HTTP methods.
public enum HTTPMethod: String {
    case get
    case post
    case put
    case delete
    
    /// Returns the raw value of the HTTP method as a string.
    public var rawValue: String {
        switch self {
        case .get: return "GET"
        case .post: return "POST"
        case .put: return "PUT"
        case .delete: return "DELETE"
        }
    }
}
