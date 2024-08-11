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
    
    typealias Row = CategoryRowFeature.State
    typealias RowAction = CategoryRowFeature.Action
    
    @Reducer(state: .equatable)
    enum Path {
        case factList(FactsListFeature)
    }
    
    @Reducer(state: .equatable)
    enum Destination {
        case commonAd(CommonAdFeature)
    }
    
    @ObservableState
    struct State: Equatable {
        
        @Presents
        var alert: AlertState<Action.Alert>?
        
        @Presents
        var destination: Destination.State?
        
        var loadingState: LoadingState = .idle
        var rows: IdentifiedArrayOf<Row> = .init()
        var path: StackState<Path.State> = .init()
                
        fileprivate var selectedRowId: Row.ID?
    }
    
    enum Action {
        case fetchData
        case dataFetchSuccess(IdentifiedArrayOf<Row>)
        case dataFetchFail(withErrorMessage: String)
        case completeAd
        
        case displayFact(for: Row.ID)
        
        case rowAction(IdentifiedAction<Row.ID, RowAction>)
    
        case alert(PresentationAction<Alert>)
        case destination(PresentationAction<Destination.Action>)
        case path(StackActionOf<Path>)
        
        enum Alert: Equatable {
            case showAd
        }
    }

    let apiService: APIClient = .init()
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .fetchData:
                return fetchData(&state)
            case .dataFetchSuccess(let rows):
                return dataFetchSuccess(with: rows, &state)
            case .dataFetchFail(let errorMessage):
                return dataFetchFail(with: errorMessage, &state)
            case .alert(let action):
                return handleAlertActions(action, &state)
            case .completeAd:
                return completeAd(&state)
            case .displayFact(let id):
                return displayFacts(for: id, &state)
            case .destination(let action):
                return destination(action, &state)
            case .path:
                return .none
            case .rowAction(let action):
                return handleRowActions(action, &state)
            }
        }
        .ifLet(\.$alert, action: \.alert)
        .forEach(\.path, action: \.path)
        .ifLet(\.$destination, action: \.destination)
        .forEach(\.rows, action: \.rowAction) {
            CategoryRowFeature()
        }
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
            case .canceled:
                return
            }
        }
    }
    
    func dataFetchSuccess(with rows: IdentifiedArrayOf<Row>, _ state: inout State) -> Effect<Action> {
        state.loadingState = rows.isEmpty ? .failed : .success
        state.rows = rows
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
    
    func handleRowActions(_ action: IdentifiedAction<Row.ID, RowAction>, _ state: inout State) -> Effect<Action> {
        switch action {
        case .element(let id, let action):
            guard case .didSelect = action else {
                return .none
            }
            state.selectedRowId = id
            let row = state.rows[id]
            if let alertState = buildAlert(for: row) {
                state.alert = alertState
                return .none
            }
            return .send(.displayFact(for: id))
        }
    }
    
    func completeAd(_ state: inout State) -> Effect<Action> {
        guard let selectedId = state.selectedRowId else {
            return .none
        }
        if state.rows[selectedId].contentStatus == .premium {
            state.rows[selectedId].contentStatus = .free
        }
        return .none
    }
    
    func displayFacts(for rowId: Row.ID, _ state: inout State) -> Effect<Action> {
        let row = state.rows[rowId]
        let content = row.content
        let factsListState: FactsListFeature.State = .init(
            title: row.title,
            items: content.map {
                .init(id: $0.id, title: $0.title, imageURL: $0.imageURL)
            }
        )
        state.path.append(.factList(factsListState))
        state.selectedRowId = nil
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
                guard let rowId = state.selectedRowId else {
                    return .none
                }
                return .concatenate(.send(.completeAd), .send(.displayFact(for: rowId)))
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
                state.selectedRowId = nil
            }
            return .none
        }
    }
    
    func buildAlert(for row: Row) -> AlertState<Action.Alert>? {
        let status = row.contentStatus
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
    
    func mapApiCategories(_ apiCategories: [APIModel.Categorie]) -> IdentifiedArrayOf<Row> {
        let result = apiCategories.enumerated().map { offset, apiCategory -> Row in
            let contentStatus: CategoryRowFeature.ContentStatus =
            switch apiCategory.status {
            case .free: .free
            case.premium: .premium
            case .comingSoon: .comingSoon
            }
                return .init(
                    id: offset,
                    title: apiCategory.title,
                    subtitle: apiCategory.description,
                    imageURL: apiCategory.imageURL,
                    contentStatus: contentStatus,
                    content: apiCategory.content?.enumerated().map { .init(id: $0.offset, title: $0.element.fact, imageURL: $0.element.image) } ?? [],
                    imageState: .init(id: apiCategory.order, imageURL: apiCategory.imageURL)
                )
        }
        return .init(uniqueElements: result)
    }
}
