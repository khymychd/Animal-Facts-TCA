//

import Foundation
import NetworkClient

struct APIClient {
    
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
    
    private let networkClient: NetworkDispatcher = .init()
    
    func fetchAnimalList() async -> Result<[APIModel.Categorie], APIError> {
        let endPoint: CategoriesEndPoint = .animals
        return await networkClient.performRequest(for: endPoint, decodeTo: [APIModel.Categorie].self)
    }
    
    func loadResource(from url: String) async -> Result<Data, APIError> {
        guard let url = URL(string: url) else {
            return .failure(.invalidURL)
        }
        return await networkClient.fetchData(for: .init(url: url))
    }
}
