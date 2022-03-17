import UIKit
import Foundation

extension APIScope {
    /// https://vk.com/dev/notifications
    public enum Notifications: APIMethod {
        case get
        case markAsViewed
    }
}
