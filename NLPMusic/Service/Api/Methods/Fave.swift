import UIKit
import Foundation

extension APIScope {
    /// https://vk.com/dev/fave
    public enum Fave: APIMethod {
        case addGroup
        case addLink
        case addUser
        case getLinks
        case getMarketItems
        case getPhotos
        case getPosts
        case getUsers
        case getVideos
        case removeGroup
        case removeLink
        case removeUser
    }
}
