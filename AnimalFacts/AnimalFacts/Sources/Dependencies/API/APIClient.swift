//

import Foundation
import NetworkClient

struct APIClient {
    
    enum CategoriesEndPoint: EndPoint {
        
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
    
    func loadResource(from url: String) async -> Data? {
        let result = await networkClient.fetchData(for: .init(url: .init(string: url)!))
        switch result {
        case .success(let success):
            return success
        case .failure(let failure):
            return nil
        }
    }
}
