import UIKit
import Foundation

extension APIScope {
    /// https://vk.com/dev/utils
    public enum Utils: APIMethod {
        case checkLink
        case deleteFromLastShortened
        case getLastShortenedLinks
        case getLinkStats
        case getServerTime
        case getShortLink
        case resolveScreenName
    }
}
