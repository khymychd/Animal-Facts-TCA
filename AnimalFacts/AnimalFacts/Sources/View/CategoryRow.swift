//

import ComposableArchitecture
import SwiftUI

struct CategoryRow: View {
    
    let store: StoreOf<CategoryRowFeature>
    
    var body: some View {
        WithPerceptionTracking {
            HStack(alignment: .top, spacing: 0) {
                AsyncImageWithFallback(store: store.scope(state: \.imageState, action: \.imageAction))
                    .aspectRatio(12 / 9, contentMode: .fit)
                    .padding(.all, 5)
                    .frame(minWidth: 121)
                VStack(alignment: .leading) {
                    Group {
                        Text(store.title)
                            .font(.system(size: 17))
                        Text(store.subtitle)
                            .font(.system(size: 12))
                    }
                    .padding(.horizontal, 5)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Spacer()
                    
                    if store.contentStatus == .premium {
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
                if store.contentStatus == .comingSoon {
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
            .aspectRatio(375 / 100, contentMode: .fill)
            .onTapGesture {
                store.send(.didSelect)
            }
        }
    }
}
