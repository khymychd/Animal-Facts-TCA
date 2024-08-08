//
import ComposableArchitecture
import UIKit.UIImage

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
        let content: [Content]?
        fileprivate let imageUrl: String
    }
    
    @ObservableState
    struct State {
        var isLoading: Bool = false
        var items: [Item] = []
    }
    
    enum Action {
        case fetchData
        case dataFetchSuccess([Item])
        case dataFetchFail(withErrorMessage: String)
        case didSelectItem(atIndex: Int)
        case markItemAsFree(atIndex: Int)
        case setImage(UIImage?, Int)
    }
    
    let apiService: APIClient = .init()
    
    var body: some Reducer<State, Action> {
        Reduce {state, action in
            switch action {
            case .fetchData:
                state.isLoading = true
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
                state.isLoading = false
                state.items = items
                return .run { send in
                    for (index, item) in items.enumerated() {
                        let imageData = await apiService.loadResource(from: item.imageUrl)
                        await send.callAsFunction(.setImage(UIImage(data: imageData!), index))
                    }
                }
            case .dataFetchFail(let errorMessage):
                print(errorMessage)
                state.isLoading = false
                return .none
            case .didSelectItem(let index):
                let itemStatus = state.items[index].contentStatus
                print(itemStatus)
                return .none
            case .markItemAsFree(let index):
                state.items[index].contentStatus = .free
                return .none
            case .setImage(let image, let index):
                state.items[index].image = image
                return .none
            }
        }
    }
}
