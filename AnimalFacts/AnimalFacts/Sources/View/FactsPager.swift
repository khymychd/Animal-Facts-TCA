//

import ComposableArchitecture
import SwiftUI

struct FactsPager: View {
    
    @Perception.Bindable
    var store: StoreOf<FactsListFeature>
    
    @Environment(\.horizontalSizeClass)
    var horizontalSizeClass
    
    @Environment(\.verticalSizeClass)
    var verticalSizeClass
    
    var body: some View {
        WithPerceptionTracking {
            TabView(selection: $store.selectedIndex.sending(\.changeSelectedItem)) {
                ForEach(store.items, id: \.id) { item in
                    WithPerceptionTracking {
                        VStack(spacing: 0) {
                            Image(systemName: "photo.fill")
                                .resizable()
                                .aspectRatio(315 / 234,contentMode: .fit)
                                .padding(.all, 10)
                            Text(item.title)
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
                                    store.send(.forward)
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
                        .tag(item.id)
                    }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: store.selectedIndex)
            .navigationTitle(store.title)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(
                leading: navigationBarButton("arrow.left") {
                    store.send(.dismiss)
                },
                trailing: navigationBarButton("square.and.arrow.up") {
                    
                }
            )
            .background(Color.background)
            .toolbarBackground(Color.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
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
    
    @ViewBuilder
    private func navigationBarButton(_ name: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: name)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .tint(.black)
        }
    }
}

#Preview {
    NavigationStack {
        FactsPager(store: .init(initialState: .init(title: "Some title", items: .init()), reducer: {
            FactsListFeature()
        }))
    }
}
