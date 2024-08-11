//

import ComposableArchitecture
import SwiftUI

struct FactItem: View {
    
    let store: StoreOf<FactItemFeature>
    
    @Environment(\.horizontalSizeClass)
    var horizontalSizeClass
    
    @Environment(\.verticalSizeClass)
    var verticalSizeClass
    
    var body: some View {
        WithPerceptionTracking {
            VStack(spacing: 0) {
                AsyncImageWithFallback(store: store.scope(state: \.imageState, action: \.imageAction))
                    .aspectRatio(315 / 234,contentMode: .fit)
                    .padding(.all, 10)
                Text(store.title)
                    .multilineTextAlignment(.center)
                    .frame(minHeight: 100, alignment: .top)
                    .padding([.top, .horizontal], 7)
                HStack() {
                    directionButton(.back) {
                        store.send(.back)
                    }
                    .disabled(!store.hasPrevious)
                    Spacer()
                    directionButton(.forward) {
                        store.send(.next)
                    }
                    .disabled(!store.hasNext)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 22)
            }
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(radius: 7, y: 7)
            .padding(.horizontal, horizontalSizeClass == .compact ? 20 : 120)
            .padding(.vertical, verticalSizeClass == .compact ? 20 : 60)
            .tag(store.id)
        }
    }
    
    @ViewBuilder
    private func directionButton(_ image: UIImage, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(uiImage: image)
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 52, height: 52)
                .tint(.black)
        }
    }
}

#Preview {
    ZStack {
        Color.background
        FactItem(
            store: .init(initialState: .init(
                id: 0,
                title: "Fact Text",
                imageState: .init(id: 0, imageURL: ""),
                hasNext: true,
                hasPrevious: false
            ), reducer: {
                FactItemFeature()
            }
            )
        )
    }
    .ignoresSafeArea()
}
