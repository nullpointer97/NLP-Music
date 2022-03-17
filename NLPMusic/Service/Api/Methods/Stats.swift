import UIKit
import Foundation

extension APIScope {
    /// https://vk.com/dev/stats
    public enum Stats: APIMethod {
        case get
        case getPostReach
        case trackVisitor
    }
}
