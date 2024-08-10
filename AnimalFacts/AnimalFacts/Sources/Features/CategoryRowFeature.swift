//

import ComposableArchitecture

@Reducer
struct CategoryRowFeature {
    
    enum ContentStatus: Equatable {
        case free
        case premium
        case comingSoon
    }
    
    struct Content: Equatable, Identifiable {
        let id: Int
        let title: String
        let imageURL: String
    }
    
    @ObservableState
    struct State: Equatable, Identifiable {
        let id: Int
        let title: String
        let subtitle: String
        let imageURL: String
        var contentStatus: ContentStatus
        var content: [Content] 
        var imageState: AsyncImageLoadingFeature.State
    }
    
    enum Action {
        case didSelect
        case imageAction(AsyncImageLoadingFeature.Action)
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .didSelect:
                return .none
            case .imageAction:
                return .none
            }
        }
        Scope(state: \.imageState, action: \.imageAction) {
            AsyncImageLoadingFeature()
        }
    }
}
