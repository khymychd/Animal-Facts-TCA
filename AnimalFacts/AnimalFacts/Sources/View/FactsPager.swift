//

import ComposableArchitecture
import SwiftUI

fileprivate struct ImageSource: Transferable {
    
    static var transferRepresentation: some TransferRepresentation {
        ProxyRepresentation(exporting: \.image)
    }
    
    var image: Image
    var caption: String
}

struct FactsPager: View {
    
    @Perception.Bindable
    var store: StoreOf<FactsListFeature>
    
    var body: some View {
        WithPerceptionTracking {
            TabView(selection: $store.selectedIndex.sending(\.changeSelectedItem)) {
                ForEachStore(store.scope(state: \.items, action: \.itemAction)) { store in
                    FactItem(store: store)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: store.selectedIndex)
            .navigationTitle(store.title)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(
                leading: Button(action: { store.send(.dismiss) }) {
                    Image(systemName: "arrow.left")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .tint(.black)
                },
                trailing:
                    WithPerceptionTracking {
                        let item = ImageSource(image: .init(uiImage: store.image ?? .init()), caption: store.caption)
                        ShareLink(item: item, preview: SharePreview("item.caption", image: item)) {
                            Image(systemName: "square.and.arrow.up")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .tint(.black)
                        }
                        .disabled(!store.canShare)
                    }
            )
            .background(Color.background)
            .toolbarBackground(Color.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}
