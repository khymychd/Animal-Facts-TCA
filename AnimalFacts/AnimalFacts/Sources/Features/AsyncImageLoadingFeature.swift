//

import ComposableArchitecture
import UIKit.UIImage

@Reducer
struct AsyncImageLoadingFeature {
    
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
        case fetchResult(Result<UIImage, ImageFetchError>)
    }
    
    fileprivate enum CancelID: Equatable, Hashable {
        case fetchImage
    }
    
    @Dependency(\.apiClient.imageProvider) var imageProvider
    
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
            let imageFetchResult = await imageProvider.fetchImage(url)
            switch imageFetchResult {
            case .success(let image):
                await send.callAsFunction(.fetchResult(.success(image)))
            case .failure(let failure):
                debugPrint(failure.localizedDescription)
                await send.callAsFunction(.fetchResult(.failure(.other(failure))))
            case .canceled:
                await send.callAsFunction(.cancelFetchImage)
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
    
    func fetchResult(_ result: Result<UIImage, ImageFetchError>, _ state: inout State) -> Effect<Action> {
        switch result {
        case .success(let success):
            state.loadingState = .success
            state.image = success
        case .failure(let failure):
            debugPrint(failure.localizedDescription)
            state.loadingState = .failed
        case .canceled:
            state.loadingState = .idle
        }
        return .none
    }
}
