//

import ComposableArchitecture
import SwiftUI

struct CommonAd: View {
    
    let store: StoreOf<CommonAdFeature>
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
            ProgressView()
                .progressViewStyle(.circular)
                .tint(.black)
        }
        .ignoresSafeArea()
        .onAppear(perform: {
            store.send(.onAppear)
        })
    }
}

#Preview {
    CommonAd(
        store: .init(
            initialState: .init(),
            reducer: {
                CommonAdFeature()
            }
        )
    )
}
