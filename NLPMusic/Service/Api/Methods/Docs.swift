import UIKit
import Foundation

extension APIScope {
    /// https://vk.com/dev/docs
    public enum Docs: APIMethod {
        case add
        case delete
        case edit
        case get
        case getById
        case getMessagesUploadServer
        case getTypes
        case getUploadServer
        case getWallUploadServer
        case save
        case search
    }
}
