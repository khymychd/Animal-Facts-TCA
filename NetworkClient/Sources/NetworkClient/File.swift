//

import Foundation

public enum Result<T: Sendable, E: Error>: Sendable {
    case success(T)
    case failure(E)
    case canceled
}
