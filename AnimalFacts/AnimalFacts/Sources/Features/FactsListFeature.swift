//

import ComposableArchitecture

@Reducer
struct FactsListFeature {
    
    struct Item: Identifiable, Equatable, Hashable {
        let id: Int
        let title: String
        let imageURL: String
    }
    
    @ObservableState
    struct State: Equatable {
        fileprivate (set) var title: String = ""
        
        var selectedIndex: Int = 0
        var items: [Item]
        
        var hasNext: Bool {
            selectedIndex < (items.count - 1)
        }
        
        var hasPrevious: Bool {
            selectedIndex > 0
        }
    }
    
    enum Action: Equatable {
        case dismiss
        case forward
        case back
        case changeSelectedItem(atIndex: Int)
    }
    
    @Dependency(\.dismiss) var dismiss
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .forward:
                if state.hasNext {
                    state.selectedIndex += 1
                }
                return .none
            case .back:
                if state.hasPrevious {
                    state.selectedIndex -= 1
                }
                return .none
            case .changeSelectedItem(atIndex: let index):
                state.selectedIndex = index
                return .none
            case .dismiss:
                return .run { send in
                    await dismiss()
                }
            }
        }
    }
}
