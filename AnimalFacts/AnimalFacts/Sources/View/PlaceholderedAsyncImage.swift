//

import ComposableArchitecture
import SwiftUI

#warning("Rename Please")
struct PlaceholderedAsyncImage: View {
    
    let store: StoreOf<AsyncImageLoadingFeature>
    
    var body: some View {
        WithPerceptionTracking {
            if store.loadingState == .success, let image = store.image {
                Image(uiImage: image)
                    .resizable()
            } else {
                Image(systemName: "photo.fill")
                    .resizable()
                    .foregroundStyle(Color.gray)
                    .overlay {
                        if store.loadingState == .loading {
                            ProgressView()
                        }
                    }
                    .onAppear(perform: {
                        store.send(.fetchImageIfNeeded)
                    })
                    .onDisappear(perform: {
                        store.send(.cancelFetchImage)
                    })
            }
        }
    }
}
