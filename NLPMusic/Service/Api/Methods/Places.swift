import UIKit
import Foundation

extension APIScope {
    /// https://vk.com/dev/places
    public enum Places: APIMethod {
        case add
        case checkin
        case getById
        case getCheckins
        case getTypes
        case search
    }
}
