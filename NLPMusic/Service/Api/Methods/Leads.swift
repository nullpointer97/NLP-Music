import UIKit
import Foundation

extension APIScope {
    /// https://vk.com/dev/leads
    public enum Leads: APIMethod {
        case checkUser
        case complete
        case getStats
        case getUsers
        case metricHit
        case start
    }
}
