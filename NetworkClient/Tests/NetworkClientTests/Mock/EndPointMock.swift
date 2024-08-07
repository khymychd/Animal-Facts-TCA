//

import Foundation
@testable import NetworkClient

struct EndPointMock: EndPoint {
    
    var host: URL {
        URL(string: "https://example.com")!
    }
    
    var path: String {
        ""
    }
    
    var method: HTTPMethod {
        .get
    }
}
