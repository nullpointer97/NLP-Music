import UIKit
import Foundation

extension APIScope {
    /// https://vk.com/dev/messages
    public enum Messages: APIMethod {
        case addChatUser
        case allowMessagesFromGroup
        case createChat
        case delete
        case deleteChatPhoto
        @available(*, deprecated)
        case deleteDialog
        case deleteConversation
        case denyMessagesFromGroup
        case editChat
        @available(*, deprecated)
        case get
        case getByConversationMessageId
        case getById
        case getChat
        @available(*, deprecated)
        case getChatUsers
        case getConversations
        case getConversationsById
        case getConversationMembers
        @available(*, deprecated)
        case getDialogs
        case getHistory
        case getHistoryAttachments
        case getLastActivity
        case getLongPollHistory
        case getLongPollServer
        case isMessagesFromGroupAllowed
        @available(*, deprecated)
        case markAsAnsweredDialog
        case markAsAnsweredConversation
        case markAsImportant
        @available(*, deprecated)
        case markAsImportantDialog
        case markAsImportantConversation
        case markAsRead
        case removeChatUser
        case restore
        case search
        case searchConversations
        @available(*, deprecated)
        case searchDialogs
        case send
        case setActivity
        case setChatPhoto
    }
}
