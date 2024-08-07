//

import Foundation

/// Protocol defining the requirements for an API endpoint.
public protocol EndPoint {
    
    /// The host of the endpoint
    var host: URL { get }
    
    /// The path of the endpoint.
    var path: String { get }
    
    /// The HTTP method used for the request.
    var method: HTTPMethod { get }
    
    /// The headers included in the request.
    var headers: [String: String]? { get }
    
    /// The query parameters included in the request.
    var query: [String: String]? { get }
    
    /// The payload data included in the request.
    var payload: [AnyHashable: Any]? { get }
}

// MARK: - EndPoint + Default
public extension EndPoint {
    
    var headers: [String: String]? { nil }
    
    var query: [String: String]? { nil }
    
    var payload: [AnyHashable: Any]? { nil }
    
    /// Converts the payload dictionary into Data.
    ///
    /// - Returns: The payload data, or nil if the payload is nil or serialization fails.
    var payloadData: Data? {
        guard let payload = payload else { return nil }
        do {
            let data = try JSONSerialization.data(withJSONObject: payload, options: [])
            return data
        } catch {
            debugPrint("‼️ Serialization failed with error: \(error.localizedDescription)\nFor payload \(payload)")
            return nil
        }
    }
    
    /// URLRequest by End Point Fields
    ///
    /// - Returns: The payload data, or nil if the payload is nil or serialization fails.
    var urlRequest: URLRequest {
        guard var urlComponents = URLComponents(url: host, resolvingAgainstBaseURL: false) else {
            debugPrint("‼️ URLComponents init failed for host: \(host.absoluteString)")
            fatalError()
        }
        urlComponents.path = path
        if let query, !query.isEmpty {
            let queryItems: [URLQueryItem] = query.map { .init(name: $0.key, value: $0.value) }
            urlComponents.queryItems = queryItems
        }
        guard let url = urlComponents.url else {
            debugPrint("‼️ URL getting failed!")
            fatalError()
        }
        var result = URLRequest(url: url)
        result.httpMethod = method.rawValue
        result.httpBody = payloadData
        if let headers, !headers.isEmpty {
            headers.forEach {
                result.setValue($0.value, forHTTPHeaderField: $0.key)
            }
        }
        return result
    }
}
