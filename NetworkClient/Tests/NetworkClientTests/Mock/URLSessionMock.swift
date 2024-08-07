//

import Foundation
@testable import NetworkClient

class URLSessionMock: URLSessionAsyncDataFetchable {
    
    var nextData: Data?
    var nextResponse: URLResponse?
    var nextError: Error?

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        if let error = nextError {
            throw error
        }
        let data = nextData ?? Data()
        let response = nextResponse ?? HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        return (data, response)
    }
}
