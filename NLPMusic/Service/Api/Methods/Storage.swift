import UIKit
import Foundation

extension APIScope {
    /// https://vk.com/dev/storage
    public enum Storage: APIMethod {
        case get
        case getKeys
        case set
    }
}
