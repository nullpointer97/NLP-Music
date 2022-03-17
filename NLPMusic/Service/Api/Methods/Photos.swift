import UIKit
import Foundation

extension APIScope {
    /// https://vk.com/dev/photos
    public enum Photos: APIMethod {
        case confirmTag
        case copy
        case createAlbum
        case createComment
        case delete
        case deleteAlbum
        case deleteComment
        case edit
        case editAlbum
        case editComment
        case get
        case getAlbums
        case getAlbumsCount
        case getAll
        case getAllComments
        case getById
        case getChatUploadServer
        case getComments
        case getMarketAlbumUploadServer
        case getMarketUploadServer
        case getMessagesUploadServer
        case getNewTags
        case getOwnerCoverPhotoUploadServer
        case getOwnerPhotoUploadServer
        case getTags
        case getUploadServer
        case getUserPhotos
        case getWallUploadServer
        case makeCover
        case move
        case putTag
        case removeTag
        case reorderAlbums
        case reorderPhotos
        case report
        case reportComment
        case restore
        case restoreComment
        case save
        case saveMarketAlbumPhoto
        case saveMarketPhoto
        case saveMessagesPhoto
        case saveOwnerCoverPhoto
        case saveOwnerPhoto
        case saveWallPhoto
        case search
    }
}
