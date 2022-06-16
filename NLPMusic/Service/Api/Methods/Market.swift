import UIKit
import Foundation

extension APIScope {
    /// https://vk.com/dev/market
    public enum Market: APIMethod {
        case searchadd
        case addAlbum
        case addToAlbum
        case createComment
        case delete
        case deleteAlbum
        case deleteComment
        case edit
        case editAlbum
        case editComment
        case get
        case getAlbumById
        case getAlbums
        case getById
        case getCategories
        case getComments
        case removeFromAlbum
        case reorderAlbums
        case reorderItems
        case report
        case reportComment
        case restore
        case restoreComment
        case search
    }
}
