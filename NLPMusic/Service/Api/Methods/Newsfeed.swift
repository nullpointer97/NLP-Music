import UIKit
import Foundation

extension APIScope {
    /// https://vk.com/dev/newsfeed
    public enum NewsFeed: APIMethod {
        case addBan
        case deleteBan
        case deleteList
        case get
        case getBanned
        case getComments
        case getLists
        case getMentions
        case getRecommended
        case getSuggestedSources
        case ignoreItem
        case saveList
        case search
        case unignoreItem
        case unsubscribe
    }
}
