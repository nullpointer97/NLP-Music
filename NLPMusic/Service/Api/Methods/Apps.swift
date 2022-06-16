import UIKit
import Foundation

extension APIScope {
    /// https://vk.com/dev/apps
    public enum Apps: APIMethod {
        case deleteAppRequests
        case get
        case getCatalog
        case getFriendsList
        case getLeaderboard
        case getScore
        case sendRequest
    }
}
