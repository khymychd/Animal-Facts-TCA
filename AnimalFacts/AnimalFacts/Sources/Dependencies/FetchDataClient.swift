//

import Foundation
import Dependencies
import UIKit.UIImage

struct APIClient {
    
    struct ImageProvider {
        var fetchImage: @Sendable (String) async -> Result<UIImage, ImageFetchError>
    }
    
    struct AnimalListProvider {
        var fetchAnimalList: @Sendable () async -> Result<[APIModel.Categorie], APIError>
    }
    
    var imageProvider: ImageProvider
    var animalListProvider: AnimalListProvider
}

// MARK: - ImageProvider DependencyKey
extension APIClient.ImageProvider: DependencyKey {
    
    static var liveValue: APIClient.ImageProvider = .init { url in
        @Dependency(\.apiRouter) var apiRouter
        let result = await apiRouter.fetchData(from: url)
        switch result {
        case .success(let success):
            if let image = UIImage(data: success) {
                return .success(image)
            }
            return .failure(.failureToCreateImage)
        case .failure(let failure):
            return .failure(.other(failure))
        case .canceled:
            return .canceled
        }
    }
    
    static var previewValue: APIClient.ImageProvider = .init { _ in
            .success(.placeholder)
    }
}

// MARK: - AnimalListProvider DependencyKey
extension APIClient.AnimalListProvider: DependencyKey {
    
    static var liveValue: APIClient.AnimalListProvider = .init {
        @Dependency(\.apiRouter) var apiRouter
        return await apiRouter.fetchAnimalList()
    }
    
    static var previewValue: APIClient.AnimalListProvider = .init {
        .success(.stub)
    }
}

// MARK: - DependencyKey
extension APIClient: DependencyKey {
    
    static var liveValue: APIClient = .init(imageProvider: .liveValue, animalListProvider: .liveValue)
    static var testValue: APIClient = .init(imageProvider: .testValue, animalListProvider: .testValue)
    static var previewValue: APIClient = .init(imageProvider: .testValue, animalListProvider: .testValue)
}
