//

import Dependencies

extension DependencyValues {
  
    var apiClient: APIClient {
        get { self[APIClient.self] }
        set { self[APIClient.self] = newValue }
    }
    
    var fetchDataClient: FetchDataClient {
        get { self[FetchDataClient.self] }
        set { self[FetchDataClient.self] = newValue }
    }
}
