//

import ComposableArchitecture

@Reducer
struct FactItemFeature {
    
    @ObservableState
    struct State: Equatable, Identifiable {
        let id: Int
        let title: String
        var imageState: AsyncImageLoadingFeature.State
        let hasNext: Bool
        let hasPrevious: Bool
    }
    
    enum Action {
        case next
        case back
        case imageAction(AsyncImageLoadingFeature.Action)
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .next:
                return .none
            case .back:
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
