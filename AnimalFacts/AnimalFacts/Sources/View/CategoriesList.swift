//

import ComposableArchitecture
import SwiftUI

struct CategoriesList: View {
    
    @Environment(\.horizontalSizeClass)
    var horizontalSizeClass
    
    let store: Store<CategorieListFeature.State, CategorieListFeature.Action>
    
    var body: some View {
        WithPerceptionTracking {
            NavigationStack {
                ScrollView {
                    if store.isLoading {
                        ProgressView()
                    } else {
                        LazyVStack {
                            ForEach(Array(store.items.enumerated()), id: \.offset) { element in
                                row(for: element.element)
                                    .onTapGesture {
                                        store.send(.didSelectItem(atIndex: element.offset))
                                    }
                            }
                        }
                        .padding(.horizontal, horizontalSizeClass == .compact ? 20 : 120)
                    }
                }
                .padding(.top, 1) // Needed
                .scrollIndicators(.never)
                .background(Color.background)
            }
            .task {
                store.send(.fetchData)
            }
        }
    }
    
    @ViewBuilder
    private func row(for item: CategorieListFeature.Item) -> some View {
        HStack(alignment: .top, spacing: 0) {
            Image(uiImage: item.image ?? .placeholder)
                .resizable()
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
}

//#Preview {
//    CategoriesList(, store: .init(initialState: .init(), reducer: ))
//}
