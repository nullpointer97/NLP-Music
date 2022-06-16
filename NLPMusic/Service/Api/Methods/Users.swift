import UIKit
import Foundation

extension APIScope {
    /// https://vk.com/dev/users
    public enum Users: APIMethod {
        case get
        case getFollowers
        case getNearby
        case getSubscriptions
        case isAppUser
        case report
        case search
    }
}
