//

import ComposableArchitecture

@Reducer
struct CommonAdFeature {
    
    @Dependency(\.continuousClock)
    var clock
    
    @Dependency(\.dismiss)
    var dismiss
    
    struct State: Equatable {
        let duration: Double = 2.0
    }
    
    enum Action: Equatable {
        case onAppear
        case timerFire
    }
    
    fileprivate enum CancelId: Equatable {
        case timer
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                let duration = state.duration
                return .run { send in
                    for await _ in clock.timer(interval: .seconds(duration)) {
                        await send.callAsFunction(.timerFire)
                    }
                }
                .cancellable(id: CancelId.timer)
            case .timerFire:
                return .concatenate(.cancel(id: CancelId.timer), .run { send in
                    await dismiss()
                })
            }
        }
    }
}
