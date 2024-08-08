//

import ComposableArchitecture
import UIKit.UIImage

enum LoadingState: Int, Equatable {
    case idle
    case loading
    case success
    case failed
}

@Reducer
struct CategorieListFeature {
    
    struct Item: Identifiable {
        
        enum ContentStatus {
            case free
            case premium
            case comingSoon
        }
        
        struct Content {
            let title: String
            let imageURL: String
        }
        
        let id: Int
        let title: String
        let subtitle: String
        var contentStatus: ContentStatus
        var image: UIImage?
        fileprivate (set) var imageLoadingState: LoadingState = .idle
        fileprivate let content: [Content]?
        fileprivate let imageUrl: String
    }
    
    @ObservableState
    struct State {
        var loadingState: LoadingState = .idle
        var items: [Item] = []
    }
    
    enum Action {
        case fetchData
        case dataFetchSuccess([Item])
        case dataFetchFail(withErrorMessage: String)
        case didSelectItem(atIndex: Int)
        case markItemAsFree(atIndex: Int)
        case fetchImageIfNeeded(forItemAtIndex: Int)
        case cancelFetchImage(atIndex: Int)
        case setImage(UIImage?, Int)
    }
    
    fileprivate enum CancelationID: Equatable, Hashable {
        case loadImage(atIndex: Int)
    }
    
    let apiService: APIClient = .init()
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .fetchData:
                state.loadingState = .loading
                return .run { send in
                    let fetchResult = await apiService.fetchAnimalList()
                    switch fetchResult {
                    case .success(let success):
                        let sortedDataByOrder = success.sorted(by: { $0.order < $1.order })
                        let items: [Item] = sortedDataByOrder.map {
                            let contentStatus: Item.ContentStatus =
                            switch $0.status {
                            case .free: .free
                            case.premium: .premium
                            case .comingSoon: .comingSoon
                            }
                            
                            return .init(
                                id: $0.order,
                                title: $0.title,
                                subtitle: $0.description,
                                contentStatus: contentStatus,
                                content: $0.content?.map { .init(title: $0.fact, imageURL: $0.image) },
                                imageUrl: $0.imageURL
                            )
                        }
                        return await send.callAsFunction(.dataFetchSuccess(items))
                    case .failure(let failure):
                        return await send.callAsFunction(.dataFetchFail(withErrorMessage: failure.localizedDescription))
                    }
                }
            case .dataFetchSuccess(let items):
                state.loadingState = items.isEmpty ? .failed : .success
                state.items = items
                return .none
            case .dataFetchFail(let errorMessage):
                print(errorMessage)
                state.loadingState = .failed
                return .none
            case .didSelectItem(let index):
                let itemStatus = state.items[index].contentStatus
                print(itemStatus)
                return .none
            case .markItemAsFree(let index):
                state.items[index].contentStatus = .free
                return .none
            case .setImage(let image, let index):
                state.items[index].imageLoadingState = image == nil ? .failed : .success
                state.items[index].image = image
                return .none
            case .fetchImageIfNeeded(let index):
                let item = state.items[index]
                guard item.imageLoadingState == .idle else {
                    return .none
                }
                let imageURL = item.imageUrl
                state.items[index].imageLoadingState = .loading
                return .run { send in
                    let imageFetchResult = await apiService.loadResource(from: imageURL)
                    switch imageFetchResult {
                    case .success(let imageData):
                        await send.callAsFunction(.setImage(UIImage(data: imageData), index))
                    case .failure(let failure):
                        debugPrint(failure.localizedDescription)
                        await send.callAsFunction(.setImage( nil, index))
                    }
                }
                .cancellable(id: CancelationID.loadImage(atIndex: index), cancelInFlight: true)
            case .cancelFetchImage(let index):
                let item = state.items[index]
                guard item.imageLoadingState == .loading else {
                    return .none
                }
                state.items[index].imageLoadingState = .idle
                return .cancel(id: CancelationID.loadImage(atIndex: index))
            }
        }
    }
}
