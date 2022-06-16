import UIKit
import Foundation

extension APIScope {
    /// https://vk.com/dev/likes
    public enum Likes: APIMethod {
        case add
        case delete
        case getList
        case isLiked
    }
}
