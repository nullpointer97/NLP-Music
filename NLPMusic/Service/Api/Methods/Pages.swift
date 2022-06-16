import UIKit
import Foundation

extension APIScope {
    /// https://vk.com/dev/pages
    public enum Pages: APIMethod {
        case clearCache
        case get
        case getHistory
        case getTitles
        case getVersion
        case parseWiki
        case save
        case saveAccess
    }
}
