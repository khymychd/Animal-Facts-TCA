//

import ComposableArchitecture
import UIKit.UIImage

@Reducer
struct AsyncImageLoadingFeature {
    
    enum FetchError: Error {
        case failureToCreateImage
        case other(Error)
    }
    
    @ObservableState
    struct State: Equatable, Identifiable {
        let id: Int
        let imageURL: String
        var loadingState: LoadingState = .idle
        var image: UIImage?
    }
    
    enum Action {
        case fetchImageIfNeeded
        case cancelFetchImage
        case fetchResult(Result<UIImage, FetchError>)
    }
    
    fileprivate enum CancelID: Equatable {
        case fetchImage
    }
    
    #warning("Make it as dependency")
    let apiService: APIClient = .init()
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .fetchImageIfNeeded:
                return fetchImageIfNeeded(&state)
            case .cancelFetchImage:
                return cancelFetchImage(&state)
            case .fetchResult(let result):
                return fetchResult(result, &state)
            }
        }
    }
}

// MARK: - Action Handling
private extension AsyncImageLoadingFeature {
    
    func fetchImageIfNeeded(_ state: inout State) -> Effect<Action> {
        guard state.loadingState == .idle else {
            return .none
        }
        state.loadingState = .loading
        let url = state.imageURL
        return .run { send in
            let imageFetchResult = await apiService.loadResource(from: url)
            switch imageFetchResult {
            case .success(let imageData):
                if let image = UIImage(data: imageData){
                    await send.callAsFunction(.fetchResult(.success(image)))
                    return
                }
                await send.callAsFunction(.fetchResult(.failure(.failureToCreateImage)))
            case .failure(let failure):
                debugPrint(failure.localizedDescription)
                await send.callAsFunction(.fetchResult(.failure(.other(failure))))
            }
        }
        .cancellable(id: CancelID.fetchImage, cancelInFlight: true)
    }
    
    func cancelFetchImage(_ state: inout State) -> Effect<Action> {
        guard state.loadingState == .loading else {
            return .none
        }
        state.loadingState = .idle
        return .cancel(id: CancelID.fetchImage)
    }
    
    func fetchResult(_ result: Result<UIImage, FetchError>, _ state: inout State) -> Effect<Action> {
        switch result {
        case .success(let success):
            state.loadingState = .success
            state.image = success
        case .failure(let failure):
            debugPrint(failure.localizedDescription)
            state.loadingState = .failed
        }
        return .none
    }
}
