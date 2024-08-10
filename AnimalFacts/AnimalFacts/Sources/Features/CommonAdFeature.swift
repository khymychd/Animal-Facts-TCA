//

import ComposableArchitecture

@Reducer
struct CommonAdFeature {
    
    @Dependency(\.continuousClock)
    var clock
    
    @Dependency(\.dismiss)
    var dismiss
    
    struct State: Equatable {}
    
    enum Action: Equatable {
        case onAppear
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    try await clock.sleep(for: .seconds(2))
                    await dismiss()
                }
            }
        }
    }
}
