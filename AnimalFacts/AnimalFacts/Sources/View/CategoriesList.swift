//

import ComposableArchitecture
import SwiftUI

struct CategoriesList: View {
    
    @Environment(\.horizontalSizeClass)
    var horizontalSizeClass
    
    @Perception.Bindable
    var store: StoreOf<CategoryListFeature>
    
    var body: some View {
        WithPerceptionTracking {
            NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
                contentView(for: store.loadingState)
                    .alert(store: store.scope(state: \.$alert, action: \.alert))
                    .fullScreenCover(store: store.scope(state: \.$destination, action: \.destination)) { store in
                        switch store.case {
                        case .commonAd(let commonAdFeature):
                            CommonAd(store: commonAdFeature)
                        }
                    }
            } destination: { store in
                switch store.case {
                case .factList(let factListFeature):
                    FactsPager(store: factListFeature)
                }
            }
            .task {
                store.send(.fetchData)
            }
            
        }
    }
    
    @ViewBuilder
    private func contentView(for loadingState: LoadingState) -> some View {
        switch loadingState {
        case .idle:
            backgroundContainer { EmptyView() }
        case .loading:
            backgroundContainer {
                ProgressView()
            }
        case .success:
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEachStore(store.scope(state: \.rows, action: \.rowAction)) { store in
                        CategoryRow(store: store)
                    }
                }
                .padding(.horizontal, horizontalSizeClass == .compact ? 20 : 120)
                .padding(.top, 30)
            }
            .padding(.top, 1) // Needed
            .scrollIndicators(.never)
            .background(Color.background)
        case .failed:
            backgroundContainer {
                Text("Some Error")
            }
        }
    }
    
    @ViewBuilder
    private func backgroundContainer(@ViewBuilder _ content:  () -> some View) -> some View {
        ZStack {
            Color.background
            content()
        }
        .ignoresSafeArea()
    }
}

//#Preview {
//    CategoriesList(, store: .init(initialState: .init(), reducer: ))
//}
