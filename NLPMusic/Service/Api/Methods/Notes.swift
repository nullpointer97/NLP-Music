import UIKit
import Foundation

extension APIScope {
    /// https://vk.com/dev/notes
    public enum Notes: APIMethod {
        case add
        case createComment
        case delete
        case deleteComment
        case edit
        case editComment
        case get
        case getById
        case getComments
        case restoreComment
    }
}
