import UIKit
import Foundation

extension APIScope {
    /// https://vk.com/dev/groups
    public enum Groups {
        case addCallbackServer
        case addLink
        case approveRequest
        case banUser
        case create
        case deleteCallbackServer
        case deleteLink
        case edit
        case editCallbackServer
        case editLink
        case editManager
        case editPlace
        case get
        case getBanned
        case getById
        case getCallbackConfirmationCode
        case getCallbackServers
        case getCallbackSettings
        case getCatalog
        case getCatalogInfo
        case getInvitedUsers
        case getInvites
        case getMembers
        case getRequests
        case getSettings
        case invite
        case isMember
        case join
        case leave
        case removeUser
        case reorderLink
        case search
        case setCallbackSettings
        case unbanUser
    }
}
