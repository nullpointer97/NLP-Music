import UIKit
import Foundation

extension APIScope {
    /// https://vk.com/dev/wall
    public enum Wall: APIMethod {
        case createComment
        case delete
        case deleteComment
        case edit
        case editAdsStealth
        case editComment
        case get
        case getById
        case getComments
        case getReposts
        case pin
        case post
        case postAdsStealth
        case reportComment
        case reportPost
        case repost
        case restore
        case restoreComment
        case search
        case unpin
    }
}
