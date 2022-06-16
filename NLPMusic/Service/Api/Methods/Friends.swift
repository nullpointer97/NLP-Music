import UIKit
import Foundation

extension APIScope {
    /// https://vk.com/dev/friends
    public enum Friends: APIMethod {
        case add
        case addList
        case areFriends
        case delete
        case deleteAllRequests
        case deleteList
        case edit
        case editList
        case get
        case getAppUsers
        case getByPhones
        case getLists
        case getMutual
        case getOnline
        case getRecent
        case getRequests
        case getSuggestions
        case search
    }
}
