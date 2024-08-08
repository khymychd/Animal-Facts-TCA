//

import SwiftUI

@main
struct AnimalFactsApp: App {
    var body: some Scene {
        WindowGroup {
            CategoriesList(
                store: .init(initialState: .init(), reducer: {
                    CategoryListFeature()
                })
            )
        }
    }
}
