//

import Foundation
import NetworkClient
import Dependencies

struct APIRouter {
    
    private enum CategoriesEndPoint: EndPoint {
        
        case animals
        
        var host: URL {
            .init(string: "https://raw.githubusercontent.com")!
        }
        
        var path: String {
            "/AppSci/promova-test-task-iOS/main/animals.json"
        }
        
        var method: HTTPMethod {
            .get
        }
    }
    
    private let networkDispatcher: NetworkDispatcher = .init(session: .init(configuration: .ephemeral))
    
    private init() {}
    
    func fetchAnimalList() async -> Result<[APIModel.Categorie], APIError> {
        let endPoint: CategoriesEndPoint = .animals
        return await networkDispatcher.performRequest(for: endPoint, decodeTo: [APIModel.Categorie].self)
    }
    
    func fetchData(from url: String) async -> Result<Data, APIError> {
        guard let url = URL(string: url) else {
            return .failure(.invalidURL)
        }
        return await networkDispatcher.fetchData(for: .init(url: url))
    }
}

// MARK: - DependencyKey
extension APIRouter: DependencyKey {
   
    static var liveValue: APIRouter = .init()
}
