import UIKit
import Foundation

extension APIScope {
    /// https://vk.com/dev/board
    public enum Board: APIMethod {
        case addTopic
        case closeTopic
        case createComment
        case deleteComment
        case deleteTopic
        case editComment
        case editTopic
        case fixTopic
        case getComments
        case getTopics
        case openTopic
        case restoreComment
        case unfixTopic
    }
}
