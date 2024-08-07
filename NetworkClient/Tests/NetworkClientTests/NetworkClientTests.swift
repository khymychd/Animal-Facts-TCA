import XCTest
@testable import NetworkClient

final class NetworkClientTests: XCTestCase {
    
    var urlSessionMock: URLSessionMock!
    var sut: NetworkClient!
    var endPointMock: EndPointMock!
    
    override func setUp() async throws {
        endPointMock = EndPointMock()
        urlSessionMock = URLSessionMock()
        sut = NetworkClient(session: urlSessionMock)
    }
    
    override func tearDown() async throws {
        endPointMock = nil
        urlSessionMock = nil
        sut = nil
    }
    
    func testFetchDataSuccess() async throws {
        // Given
        let expectedData = "Success".data(using: .utf8)!
        urlSessionMock.nextData = expectedData
        urlSessionMock.nextResponse = HTTPURLResponse(url: URL(string: "https://example.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        
        // When
        let result = await sut.fetchData(for: URLRequest(url: URL(string: "https://example.com")!))
        
        // Then
        switch result {
        case .success(let data):
            XCTAssertEqual(data, expectedData)
        case .failure:
            XCTFail("Expected success, but got failure")
        }
    }
    
    func testFetchDataFailureRequestError() async throws {
        // Given
        urlSessionMock.nextError = MockError.someError
        
        // When
        let result = await sut.fetchData(for: URLRequest(url: URL(string: "https://example.com")!))
        
        // Then
        switch result {
        case .success:
            XCTFail("Expected failure, but got success")
        case .failure(let error):
            XCTAssertEqual(error, .requestFailed(MockError.someError))
        }
    }
    
    func testFetchDataFailureInvalidResponse() async throws {
        // Given
        urlSessionMock.nextResponse = URLResponse()
        
        // When
        let result = await sut.fetchData(for: URLRequest(url: URL(string: "https://example.com")!))
        
        // Then
        switch result {
        case .success:
            XCTFail("Expected failure, but got success")
        case .failure(let error):
            XCTAssertEqual(error, .invalidResponse)
        }
    }
    
    func testPerformRequestSuccess() async throws {
        let jsonString = "{\"message\":\"Hello\"}"
        let expectedObject = MockDecodable(message: "Hello")
        urlSessionMock.nextData = jsonString.data(using: .utf8)
        urlSessionMock.nextResponse = HTTPURLResponse(url: URL(string: "https://example.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
    
        // When
        let result: Result<MockDecodable, APIError> = await sut.performRequest(for: endPointMock, decodeTo: MockDecodable.self)
        
        // Then
        switch result {
        case .success(let object):
            XCTAssertEqual(object, expectedObject)
        case .failure:
            XCTFail("Expected success, but got failure")
        }
    }
    
    func testPerformRequestDecodingError() async throws {
        // Given
        urlSessionMock.nextData = "Invalid JSON".data(using: .utf8)
        urlSessionMock.nextResponse = HTTPURLResponse(url: URL(string: "https://example.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        
        // When
        let result: Result<MockDecodable, APIError> = await sut.performRequest(for: endPointMock, decodeTo: MockDecodable.self)
        
        // Then
        switch result {
        case .success:
            XCTFail("Expected failure, but got success")
        case .failure(let error):
            switch error {
            case .decodingError:
                XCTAssertTrue(true)
            default:
                XCTFail("Expected decoding error, but got \(error)")
            }
        }
    }
    
    func testPerformRequestFailure() async throws {
        // Given
        urlSessionMock.nextResponse = HTTPURLResponse(url: URL(string: "https://example.com")!, statusCode: 403, httpVersion: nil, headerFields: nil)
        
        // When
        let result: Result<MockDecodable, APIError> = await sut.performRequest(for: endPointMock, decodeTo: MockDecodable.self)
        
        // Then
        switch result {
        case .success:
            XCTFail("Expected failure, but got success")
        case .failure(let error):
            XCTAssertEqual(error, APIError.forbidden)
        }
    }
}
