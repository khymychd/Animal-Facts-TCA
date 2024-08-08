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
        fileprivate let content: [Content]?
        fileprivate let imageUrl: String
    }
    
    @ObservableState
    struct State {
        var loadingState: LoadingState = .idle
        var items: [Item] = []
        var isDisplayAd: Bool = false
        @Presents
        var alert: AlertState<Action.Alert>?
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
        
#warning("Try to find the problem with @CasePathable")
        //        @CasePathable
        enum Alert: Equatable {
            case showAd(Int)
        }
    }
    
    fileprivate enum CancelationID: Equatable, Hashable {
        case loadImage(atIndex: Int)
    }
    
    let apiService: APIClient = .init()
    @Dependency(\.continuousClock) var clock
    
    var body: some Reducer<State, Action> {
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
                return handleAlertActions(alert, state: &state)
            }
        }
        .ifLet(\.$alert, action: \.alert)
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
        let item = state.items[index]
        if let alertState = buildAlert(for: item, at: index) {
            state.alert = alertState
        }
        return .none
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
        state.isDisplayAd = false
        state.items[index].contentStatus = .free
        return .none
    }
}

// MARK: - Alert
private extension CategoryListFeature {
    
    func handleAlertActions(_ action: PresentationAction<Action.Alert>, state: inout State) -> Effect<Action> {
        switch action {
        case .presented(.showAd(let index)):
            state.isDisplayAd = true
            return .run { send in
                try await clock.sleep(for: .seconds(2))
                await send.callAsFunction(.completeAd(forItemAtIndex: index))
            }
        case .dismiss:
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
                ButtonState(action: .showAd(index)) {
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
                content: $0.content?.map { .init(title: $0.fact, imageURL: $0.image) },
                imageUrl: $0.imageURL
            )
        }
    }
}
