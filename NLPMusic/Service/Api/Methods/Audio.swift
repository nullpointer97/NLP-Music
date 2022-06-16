import UIKit
import Foundation

extension APIScope {
    /// https://vk.com/dev/audio
    public enum Audio: APIMethod {
        case get
        case getById
        case getLyrics
        case search
        case getUploadServer
        case save
        case add
        case delete
        case edit
        case reorder
        case getAlbums
        case addAlbum
        case editAlbum
        case deleteAlbum
        case moveToAlbum
        case setBroadcast
        case getBroadcastList
        case getRecommendations
        case getPopular
        case getCount
    }
}
