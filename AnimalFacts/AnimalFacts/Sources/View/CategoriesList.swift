//

import ComposableArchitecture
import SwiftUI

struct CategoriesList: View {
    
    @Environment(\.horizontalSizeClass)
    var horizontalSizeClass
    
    let store: Store<CategoryListFeature.State, CategoryListFeature.Action>
    
    var body: some View {
        WithPerceptionTracking {
            NavigationStack {
                contentView(for: store.loadingState)
            }
            .overlay(content: {
                if store.isDisplayAd {
                    ZStack {
                        Color.gray.opacity(0.5)
                        ProgressView()
                    }
                    .ignoresSafeArea()
                }
            })
            .task {
                store.send(.fetchData)
            }
            .alert(store: store.scope(state: \.$alert, action: \.alert))
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
                    ForEach(Array(store.items.enumerated()), id: \.offset) { element in
                        row(for: element.element, at: element.offset)
                            .onTapGesture {
                                store.send(.didSelectItem(atIndex: element.offset))
                            }
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
    
    @ViewBuilder
    private func row(for item: CategoryListFeature.Item, at index: Int) -> some View {
        HStack(alignment: .top, spacing: 0) {
            image(for: item, at: index)
                .aspectRatio(12 / 9, contentMode: .fit)
                .padding(.all, 5)
                .frame(minWidth: 121)
            VStack(alignment: .leading) {
                Group {
                    Text(item.title)
                        .font(.system(size: 17))
                    Text(item.subtitle)
                        .font(.system(size: 12))
                }
                .padding(.horizontal, 5)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                if item.contentStatus == .premium {
                    HStack(alignment: .center, spacing: 0) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 12))
                        Text("Premium")
                            .font(.system(size: 16))
                    }
                    .foregroundStyle(Color.statusTint)
                }
            }
            .padding(.top, 10)
            .padding(.bottom, 7)
            .padding(.horizontal, 7)
        }
        .overlay(content: {
            if item.contentStatus == .comingSoon {
                ZStack(alignment: .trailing) {
                    Color.black.opacity(0.6)
                    Image(uiImage: .comingSoon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(.trailing, 4)
                }
            }
        })
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .shadow(radius: 2, y: 2)
        .aspectRatio(375 / 100, contentMode: .fill) // If needed static height use frame
    }
    
    @ViewBuilder
    private func image(for item: CategoryListFeature.Item, at index: Int) -> some View {
        if item.imageLoadingState == .success, let image = item.image {
            Image(uiImage: image)
                .resizable()
        } else {
            Image(systemName: "photo.fill")
                .resizable()
                .foregroundStyle(Color.gray)
                .overlay {
                    if item.imageLoadingState == .loading {
                        ProgressView()
                    }
                }
                .onAppear(perform: {
                    store.send(.fetchImageIfNeeded(forItemAtIndex: index))
                })
                .onDisappear(perform: {
                    store.send(.cancelFetchImage(atIndex: index))
                })
        }
    }
}

//#Preview {
//    CategoriesList(, store: .init(initialState: .init(), reducer: ))
//}
