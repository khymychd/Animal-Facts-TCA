// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

protocol URLSessionAsyncDataFetchable {
    
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionAsyncDataFetchable {}

public struct NetworkClient {
    
    private let session: URLSessionAsyncDataFetchable
    
    private let decoder: JSONDecoder
    
    public init(session: URLSession = .shared, decoder: JSONDecoder = .init()) {
        self.session = session
        self.decoder = decoder
    }
    
    internal init(session: URLSessionAsyncDataFetchable, decoder: JSONDecoder = .init()) {
        self.session = session
        self.decoder = decoder
    }
    
    public  func performRequest<D: Decodable>(for endPoint: EndPoint, decodeTo decodingObject: D.Type) async -> Result<D, APIError> {
        let fetchDataResult = await fetchData(for: endPoint.urlRequest)
        switch fetchDataResult {
        case .success(let data):
            do {
                let decodingResult = try decoder.decode(decodingObject, from: data)
                return .success(decodingResult)
            } catch {
                return .failure(.decodingError(error))
            }
        case .failure(let failure):
            return .failure(failure)
        }
    }
    
    public func fetchData(for request: URLRequest) async -> Result<Data, APIError> {
        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.invalidResponse)
            }
            if (200...299).contains(httpResponse.statusCode) {
                if data.isEmpty {
                    return .failure(.noData)
                }
                return .success(data)
            } else if httpResponse.statusCode == 403 {
                return .failure(.forbidden)
            }
            return .failure(.invalidResponse)
        } catch {
            return .failure(.requestFailed(error))
        }
    }
}
