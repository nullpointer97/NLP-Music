import UIKit
import Foundation

extension APIScope {
    /// https://vk.com/dev/account
    public enum Account: APIMethod {
        case banUser
        case changePassword
        case getActiveOffers
        case getAppPermissions
        case getBanned
        case getCounters
        case getInfo
        case getProfileInfo
        case getPushSettings
        case registerDevice
        case saveProfileInfo
        case setNameInMenu
        case setOffline
        case setOnline
        case setPushSettings
        case setInfo
        case setSilenceMode
        case unbanUser
        case unregisterDevice
    }
}
