//

import Foundation
import Dependencies
import UIKit.UIImage

struct FetchDataClient {
    
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
extension FetchDataClient.ImageProvider: DependencyKey {
    
    static var liveValue: FetchDataClient.ImageProvider = .init { url in
        @Dependency(\.apiClient) var apiClient
        let result = await apiClient.fetchData(from: url)
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
    
    static var previewValue: FetchDataClient.ImageProvider = .init { _ in
            .success(.placeholder)
    }
}

// MARK: - AnimalListProvider DependencyKey
extension FetchDataClient.AnimalListProvider: DependencyKey {
    
    static var liveValue: FetchDataClient.AnimalListProvider = .init {
        @Dependency(\.apiClient) var apiClient
        return await apiClient.fetchAnimalList()
    }
    
    static var previewValue: FetchDataClient.AnimalListProvider = .init {
        .success(.stub)
    }
}

// MARK: - DependencyKey
extension FetchDataClient: DependencyKey {
    
    static var liveValue: FetchDataClient = .init(imageProvider: .liveValue, animalListProvider: .liveValue)
    static var testValue: FetchDataClient = .init(imageProvider: .testValue, animalListProvider: .testValue)
    static var previewValue: FetchDataClient = .init(imageProvider: .testValue, animalListProvider: .testValue)
}
