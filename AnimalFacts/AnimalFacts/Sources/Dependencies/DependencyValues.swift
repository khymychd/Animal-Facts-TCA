//

import Dependencies

extension DependencyValues {
  
    var apiRouter: APIRouter {
        get { self[APIRouter.self] }
        set { self[APIRouter.self] = newValue }
    }
    
    var apiClient: APIClient {
        get { self[APIClient.self] }
        set { self[APIClient.self] = newValue }
    }
}
