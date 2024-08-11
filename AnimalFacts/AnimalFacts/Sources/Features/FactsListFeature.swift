//

import ComposableArchitecture
import UIKit.UIImage

@Reducer
struct FactsListFeature {
    
    struct Item {
        let id: Int
        let title: String
        let imageURL: String
    }
        
    @ObservableState
    struct State: Equatable {
        fileprivate (set) var title: String = ""
        
        var selectedIndex: Int = 0
        var items: IdentifiedArrayOf<FactItemFeature.State>
        
        private var imageState: AsyncImageLoadingFeature.State {
            items[selectedIndex].imageState
        }
        
        var image: UIImage? {
            imageState.image
        }
        
        var caption: String {
            URL(string: imageState.imageURL)?.lastPathComponent ?? title
        }
        
        var canShare: Bool {
            image != nil
        }
        
        init(title: String, items: [Item]) {
            self.title = title
            self.items = .init(
                uniqueElements: items.enumerated().map {
                    .init(id: $0.element.id,
                          title: $0.element.title,
                          imageState: .init(id: $0.element.id, imageURL: $0.element.imageURL),
                          hasNext: $0.offset < items.count - 1,
                          hasPrevious: $0.offset > 0)
                }
            )
        }
    }
    
    typealias ItemAction = IdentifiedAction<FactItemFeature.State.ID, FactItemFeature.Action>
    
    enum Action {
        case dismiss
        case itemAction(ItemAction)
        case changeSelectedItem(atIndex: Int)
    }
    
    @Dependency(\.dismiss) var dismiss
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .itemAction(let action):
                return handleItemAction(action, &state)
            case .changeSelectedItem(atIndex: let index):
                state.selectedIndex = index
                return .none
            case .dismiss:
                return .run { send in
                    await dismiss()
                }
            }
        }
        .forEach(\.items, action: \.itemAction) {
            FactItemFeature()
        }
    }
}

// MARK: - Item Action Handling
private extension FactsListFeature {
    
    func handleItemAction(_ action: ItemAction, _ state: inout State) -> Effect<Action> {
        switch action {
        case let .element(elementId, itemAction):
            switch itemAction {
            case .next:
                if state.items[elementId].hasNext {
                    let next = state.selectedIndex + 1
                    return .send(.changeSelectedItem(atIndex: next))
                }
                return .none
            case .back:
                if state.items[elementId].hasPrevious {
                    let next = state.selectedIndex - 1
                    return .send(.changeSelectedItem(atIndex: next))
                }
                return .none
            case .imageAction:
                return .none
            }
        }
    }
}
