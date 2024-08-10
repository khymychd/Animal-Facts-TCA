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
struct CategoryListFeature {
    
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
        fileprivate (set) var contentStatus: ContentStatus
        fileprivate (set) var image: UIImage?
        fileprivate (set) var imageLoadingState: LoadingState = .idle
        fileprivate var content: [Content] = []
        fileprivate let imageUrl: String
    }
    
    @Reducer
    enum Path {
        case factList(FactsListFeature)
    }
    
    @Reducer
    enum Destination {
        case commonAd(CommonAdFeature)
    }
    
    @ObservableState
    struct State {
        
        @Presents
        var alert: AlertState<Action.Alert>?
        
        @Presents
        var destination: Destination.State?
        
        var loadingState: LoadingState = .idle
        var items: [Item] = []
        var path: StackState<Path.State> = .init()
        
        fileprivate var selectedItemIndex: Int?
    }
    
    enum Action {
        case fetchData
        case dataFetchSuccess([Item])
        case dataFetchFail(withErrorMessage: String)
        case didSelectItem(atIndex: Int)
        case fetchImageIfNeeded(forItemAtIndex: Int)
        case cancelFetchImage(atIndex: Int)
        case setImage(UIImage?, Int)
        case alert(PresentationAction<Alert>)
        case completeAd(forItemAtIndex: Int)
        
        case displayFact(forItemAtIndex: Int)
       
        case destination(PresentationAction<Destination.Action>)
        case path(StackActionOf<Path>)
        
        enum Alert: Equatable {
            case showAd
        }
    }
    
    fileprivate enum CancelationID: Equatable, Hashable {
        case loadImage(atIndex: Int)
    }
    
    let apiService: APIClient = .init()
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .fetchData:
                return fetchData(&state)
            case .dataFetchSuccess(let items):
                return dataFetchSuccess(with: items, &state)
            case .dataFetchFail(let errorMessage):
                return dataFetchFail(with: errorMessage, &state)
            case .didSelectItem(let index):
                return didSelectItem(at: index, &state)
            case .setImage(let image, let index):
                return setImage(image, at: index, &state)
            case .fetchImageIfNeeded(let index):
                return fetchImageIfNeeded(forItemAt: index, &state)
            case .cancelFetchImage(let index):
                return cancelFetchImage(at: index, &state)
            case .completeAd(let index):
                return completeAd(forItemAt: index, &state)
            case .alert(let alert): // In my case @CasePathable doesn't work 🤷
                return handleAlertActions(alert, &state)
            case .displayFact(let index):
                return displayFacts(for: index, &state)
            case .path:
                return .none
            case .destination(let action):
                return destination(action, &state)
            }
        }
        .ifLet(\.$alert, action: \.alert)
        .forEach(\.path, action: \.path)
        .ifLet(\.$destination, action: \.destination)
    }
}

// MARK: - Action Handling
private extension CategoryListFeature {
    
    func fetchData(_ state: inout State) -> Effect<Action> {
        state.loadingState = .loading
        return .run { send in
            let fetchResult = await apiService.fetchAnimalList()
            switch fetchResult {
            case .success(let success):
                let sortedDataByOrder = success.sorted(by: { $0.order < $1.order })
                let items = mapApiCategories(sortedDataByOrder)
                await send.callAsFunction(.dataFetchSuccess(items))
            case .failure(let failure):
                await send.callAsFunction(.dataFetchFail(withErrorMessage: failure.localizedDescription))
            }
        }
    }
    
    func dataFetchSuccess(with items: [Item], _ state: inout State) -> Effect<Action> {
        state.loadingState = items.isEmpty ? .failed : .success
        state.items = items
        return .none
    }
    
    func dataFetchFail(with errorMessage: String, _ state: inout State) -> Effect<Action> {
#if DEBUG
        state.alert = AlertState {
            TextState("Error")
        } message: {
            TextState(errorMessage)
        }
#endif
        state.loadingState = .failed
        return .none
    }
    
    func didSelectItem(at index: Int, _ state: inout State) -> Effect<Action> {
        state.selectedItemIndex = index
        let item = state.items[index]
        if let alertState = buildAlert(for: item, at: index) {
            state.alert = alertState
            return .none
        }
        return .send(.displayFact(forItemAtIndex: index))
    }

    func fetchImageIfNeeded(forItemAt index: Int, _ state: inout State) -> Effect<Action> {
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
    }
    
    func cancelFetchImage(at index: Int, _ state: inout State) -> Effect<Action>{
        let item = state.items[index]
        guard item.imageLoadingState == .loading else {
            return .none
        }
        state.items[index].imageLoadingState = .idle
        return .cancel(id: CancelationID.loadImage(atIndex: index))
    }
    
    func setImage(_ image: UIImage?, at index: Int, _ state: inout State) -> Effect<Action> {
        state.items[index].imageLoadingState = image == nil ? .failed : .success
        state.items[index].image = image
        return .none
    }
    
    func completeAd(forItemAt index: Int, _ state: inout State) -> Effect<Action> {
        state.items[index].contentStatus = .free
        return .send(.displayFact(forItemAtIndex: index))
    }
    
    func displayFacts(for itemAtIndex: Int, _ state: inout State) -> Effect<Action> {
        let item = state.items[itemAtIndex]
        let content = item.content
        let factsListState: FactsListFeature.State = .init(
            title: item.title,
            items: content.enumerated().map {
                .init(id:$0.offset, title: $0.element.title, imageURL: $0.element.imageURL)
            }
        )
        state.path.append(.factList(factsListState))
        state.selectedItemIndex = nil
        return .none
    }
    
    func destination(_ action: PresentationAction<Destination.Action>, _ state: inout State) -> Effect<Action> {
        switch action {
        case .dismiss:
            guard let destination = state.destination else {
                return .none
            }
            switch destination {
            case .commonAd:
                return .send(.completeAd(forItemAtIndex: state.selectedItemIndex!))
            }
        case .presented:
            return .none
        }
    }
}

// MARK: - Alert
private extension CategoryListFeature {
    
    func handleAlertActions(_ action: PresentationAction<Action.Alert>, _ state: inout State) -> Effect<Action> {
        switch action {
        case .presented(.showAd):
            state.destination = .commonAd(.init())
            return .none
        case .dismiss:
            if state.destination == nil {
                state.selectedItemIndex = nil
            }
            return .none
        }
    }
    
    func buildAlert(for item: Item, at index: Int) -> AlertState<Action.Alert>? {
        let status = item.contentStatus
        switch status {
        case .free:
            return nil
        case .premium:
            return AlertState {
                TextState("Watch Ad to continue")
            } actions: {
                ButtonState(role: .cancel) {
                    TextState("Cancel")
                }
                ButtonState(action: .showAd) {
                    TextState("Show Ad")
                }
            }
        case .comingSoon:
            return AlertState {
                TextState("Coming Soon")
            } actions: {
                ButtonState(role: .cancel) {
                    TextState("Ok")
                }
            } message: {
                TextState("Stay tuned for future updates.")
            }
        }
    }
}

// MARK: - Map ApiCategories to Items
private extension CategoryListFeature {
    
    func mapApiCategories(_ apiCategories: [APIModel.Categorie]) -> [Item] {
        apiCategories.map {
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
                content: $0.content?.map { .init(title: $0.fact, imageURL: $0.image) } ?? [],
                imageUrl: $0.imageURL
            )
        }
    }
}
