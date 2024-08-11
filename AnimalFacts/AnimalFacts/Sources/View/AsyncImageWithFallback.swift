//

import ComposableArchitecture
import SwiftUI

struct AsyncImageWithFallback: View {
    
    let store: StoreOf<AsyncImageLoadingFeature>
    
    var fallBackImage: Image = Image(systemName: "photo.fill")
    
    var body: some View {
        WithPerceptionTracking {
            if store.loadingState == .success, let image = store.image {
                Image(uiImage: image)
                    .resizable()
            } else {
                    fallBackImage
                    .resizable()
                    .foregroundStyle(Color.gray)
                    .overlay {
                        if store.loadingState == .loading {
                            ProgressView()
                        }
                    }
                    .task {
                        store.send(.fetchImageIfNeeded)
                    }
            }
        }
    }
}

#Preview {
    AsyncImageWithFallback(
        store: .init(initialState: .init(
            id: 0,
            imageURL: "",
            loadingState: .loading
        ),reducer: {
            AsyncImageLoadingFeature()
        }
        )
    )
    .frame(width: 300, height: 300)
}
