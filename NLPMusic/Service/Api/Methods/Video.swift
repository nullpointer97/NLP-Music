import UIKit
import Foundation

extension APIScope {
    /// https://vk.com/dev/video
    public enum Video: APIMethod {
        case add
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
        case getAlbumsByVideo
        case getCatalog
        case getCatalogSection
        case getComments
        case hideCatalogSection
        case removeFromAlbum
        case reorderAlbums
        case reorderVideos
        case report
        case reportComment
        case restore
        case restoreComment
        case save
        case search
    }
}
