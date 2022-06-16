//
//  Conversation+Configure.swift
//  VKM
//
//  Created by Ярослав Стрельников on 15.03.2021.
//

import Foundation
import CoreStore
import SwiftyJSON

enum MessageAttachmentType: String {
    case photo = "Фотография"
    case video = "Видеозапись"
    case audio = "Аудиозапись"
    case audio_message = "Голосовое сообщение"
    case doc = "Документ"
    case link = "Ссылка"
    case market = "Товар"
    case market_album = "Подборка товаров"
    case wall = "Запись"
    case wall_reply = "Комментарий"
    case sticker = "Стикер"
    case gift = "Подарок"
    case graffity = "Граффити"
    case call = "Звонок"
    case unknown = "Неизвестное вложение"
    case none = ""
    
    static func setMultiple(_ attachmentCount: Int) -> Self.RawValue {
        let multipleAttachments = "\(attachmentCount) \(getStringByDeclension(number: attachmentCount, arrayWords: Localization.attachmentsString))"
        return multipleAttachments
    }
}

enum ConversationPeerType: String {
    case user
    case group
    case chat
    
    static func get(by rawValue: String) -> Self {
        if rawValue == "user" {
            return .user
        } else if rawValue == "group" {
            return .group
        } else {
            return .chat
        }
    }
    
    static func get(by id: Int) -> Self {
        if id > 2000000000 {
            return .chat
        } else if id < 0 {
            return .group
        } else {
            return .user
        }
    }
}

enum ReadStatus: String {
    case unreadIn
    case unreadOut
    case read
    case markedUnread
}

public enum MessageAction: String {
    case chatPhotoUpdate = "обновлена фотография беседы"
    case chatPhotoRemove = "удалена фотография беседы"
    case chatCreate = "создана беседа"
    case chatTitleUpdate = "обновлено название беседы"
    case chatInviteUser = "приглашен пользователь"
    case chatKickUser = "исключен пользователь"
    case chatKickUserWhereUserId = "вышел из беседы"
    case chatPinMessage = "закреплено сообщение"
    case chatUnpinMessage = "откреплено сообщение"
    case chatInviteUserByLink = "пользователь присоединился к беседе по ссылке"
    case unknown = ""
    
    static func action(by rawValue: String) -> Self {
        switch rawValue {
        case "chat_photo_update":
            return .chatPhotoUpdate
        case "chat_photo_remove":
            return .chatPhotoRemove
        case "chat_create":
            return .chatCreate
        case "chat_title_update":
            return .chatTitleUpdate
        case "chat_invite_user":
            return .chatInviteUser
        case "chat_kick_user":
            return .chatKickUser
        case "chat_pin_message":
            return .chatPinMessage
        case "chat_unpin_message":
            return .chatUnpinMessage
        case "chat_invite_user_by_link":
            return .chatInviteUserByLink
        default:
            return .unknown
        }
    }
}
extension Conversation {
    func configureLastMessage() -> NSAttributedString {
        guard let messageText = text, !messageText.isEmpty || (hasAttachments! || hasForwardedMessages! || hasReplyMessage!) else { return "Пустое сообщение".toAttributedString() }
        guard removedMessageFlag == 0 else { return NSAttributedString(string: "Сообщение удалено") }

        let text = (messageText.isEmpty && !hasForwardedMessages! && !hasReplyMessage! && !hasAttachments!) ? "Пустое сообщение" : messageText.replacingOccurrences(of: "\n", with: "\rConv")
        if hasForwardedMessages! {
            let forwardedMessages = "\(forwardMessagesCount!) \(getStringByDeclension(number: forwardMessagesCount!, arrayWords: Localization.forwardString))"
            let forwardedMessagesText = NSAttributedString(string: forwardedMessages, attributes: [.foregroundColor: UIColor.getAccentColor(fromType: .common), .font: ProximaNova.regular.of(size: 15)])
            return text != "" ? NSAttributedString(string: "\(text) ") + forwardedMessagesText : forwardedMessagesText
        } else if hasReplyMessage! {
            let replyMessageText = NSAttributedString(string: "Ответ", attributes: [.foregroundColor: UIColor.getAccentColor(fromType: .common), .font: ProximaNova.regular.of(size: 15)])
            return text != "" ? NSAttributedString(string: "\(text) ") + replyMessageText : replyMessageText
        } else if hasAttachments! {
            if isMultiple {
                return NSAttributedString(string: attachmentType!, attributes: [.foregroundColor: UIColor.getAccentColor(fromType: .common), .font: ProximaNova.regular.of(size: 15)])
            } else {
                let attachmentText = NSAttributedString(string: attachmentType!, attributes: [.foregroundColor: UIColor.getAccentColor(fromType: .common), .font: ProximaNova.regular.of(size: 15)])
                return text != "" ? NSAttributedString(string: "\(text) ") + attachmentText : attachmentText
            }
        } else {
            return NSAttributedString(string: text) + NSAttributedString(string: "")
        }
    }
    
    func updateConversation(_ conversation: JSON, _ action: ConversationObjectAction) {
        switch action {
        case .update(let isOut, let isCurrentPeer):
            if isCurrentPeer {
                nullableCounter()
                inRead = conversation["id"].intValue
                outRead = conversation["id"].intValue
                out = 1
            } else {
                if isOut {
                    nullableCounter()
                    inRead = conversation["id"].intValue
                    out = 1
                } else {
                    increaseCounter()
                    outRead = conversation["id"].intValue
                    out = 0
                }
            }
            lastMessageId = conversation["id"].intValue
        case .create:
            type = conversation["conversation"]["peer"]["type"].stringValue
            localId = conversation["conversation"]["peer"]["local_id"].intValue
            lastMessageId = conversation["conversation"]["last_message_id"].intValue
            inRead = conversation["conversation"]["in_read"].intValue
            outRead = conversation["conversation"]["out_read"].intValue
            canWriteAllowed = conversation["conversation"]["can_write"]["allowed"].boolValue
            canWriteReason = conversation["conversation"]["can_write"]["reason"].intValue
            majorId = conversation["conversation"]["sort_id"]["major_id"].intValue
            minorId = conversation["conversation"]["sort_id"]["minor_id"].intValue
            isMarkedUnread = conversation["conversation"]["is_marked_unread"].boolValue
            isImportant = conversation["conversation"]["sort_id"]["major_id"].intValue > 0
            isPrivateConversation = UserDefaults.standard.bool(forKey: "privateConversaionFrom\(peerId)")
            membersCount = conversation["conversation"]["chat_settings"]["members_count"].intValue
            title = conversation["conversation"]["chat_settings"]["title"].stringValue
            unreadCount = conversation["conversation"]["unread_count"].intValue
            state = conversation["conversation"]["chat_settings"]["state"].stringValue
            isGroupChannel = conversation["conversation"]["chat_settings"]["is_group_channel"].boolValue
            disabledUntil = conversation["conversation"]["push_settings"].dictionary?["disabled_until"]?.intValue ?? 0
            disabledForever = conversation["conversation"]["push_settings"].dictionary?["disabled_forever"]?.boolValue ?? false
            noSound = conversation["conversation"]["push_settings"].dictionary?["no_sound"]?.boolValue ?? false
            isTyping = false
        }
    }
    
    func updateLastMessage(_ lastMessage: JSON, _ action: ConversationObjectAction) {
        let message: JSON
        switch action {
        case .update:
            message = lastMessage
        case .create:
            message = lastMessage["last_message"]
        }
        // MARK: Last Message
        date = Self.messageTime(time: message["date"].intValue)
        dateInteger = message["date"].int
        text = message["text"].string ?? "none"
        id = message["id"].int
        fromId = message["from_id"].intValue
        out = message["out"].intValue
        peerId = message["peer_id"].intValue
        text = message["text"].stringValue
        conversationMessageId = message["conversation_message_id"].intValue
        isImportantMessage = message["important"].boolValue
        randomId = message["random_id"].intValue
        isRemovedConversation = false
        removedMessageFlag = 0
        actionType = MessageAction.action(by: message["action"]["type"].stringValue).rawValue
        
        if message["attachments"].array?.count ?? 0 == 1 {
            attachmentType = Conversation.typeAttachment(string: message["attachments"].array?.first?["type"].stringValue).rawValue
        } else {
            attachmentType = "\(message["attachments"].array?.count ?? 0) \(getStringByDeclension(number: message["attachments"].array?.count ?? 0, arrayWords: Localization.attachmentsString))"
        }
        hasAttachments = message["attachments"].array?.first?["type"].stringValue != nil
        forwardMessagesCount = message["fwd_messages"].arrayValue.count
        hasForwardedMessages = message["fwd_messages"].arrayValue.count > 0
        hasReplyMessage = !(message["reply_message"] == JSON.null)
    }
    
    func updateInterlocutor(_ conversation: JSON, _ interlocutor: JSON?, _ type: ConversationPeerType, _ action: ConversationObjectAction) {
        switch type {
        case .user:
            self.userId = interlocutor?["id"].intValue ?? 0
            self.imageStatusUrl = interlocutor?["image_status"]["images"].arrayValue.first?["url"].string
            self.name = (interlocutor?["first_name"].stringValue ?? "") + " " + (interlocutor?["last_name"].stringValue ?? "")
            self.photo100 = interlocutor?["photo_100"].stringValue ?? ""
            self.visible = interlocutor?["online_info"]["visible"].boolValue ?? false
            self.lastSeen = interlocutor?["online_info"]["last_seen"].intValue ?? 0
            self.isOnline = interlocutor?["online_info"]["is_online"].boolValue ?? false
            self.appId = interlocutor?["online_info"]["app_id"].intValue ?? 0
            self.isMobile = interlocutor?["online_info"]["is_mobile"].boolValue ?? false
            self.sex = interlocutor?["sex"].intValue ?? 0
            self.verified = interlocutor?["verified"].intValue ?? 0
            self.senderName = out == 1 ? "Вы: " : ""
            self.type = ConversationPeerType.user.rawValue
        case .group:
            self.userId = interlocutor?["id"].intValue ?? 0
            self.name = interlocutor?["name"].stringValue ?? ""
            self.photo100 = interlocutor?["photo_100"].stringValue ?? ""
            self.verified = interlocutor?["verified"].intValue ?? 0
            self.senderName = out == 1 ? "Вы: " : ""
            self.type = ConversationPeerType.group.rawValue
            self.lastSeen = 0
            self.isOnline = false
            self.appId = 0
            self.isMobile = false
        case .chat:
            switch action {
            case .update(isOut: _, isCurrentPeer: _):
                self.senderId = interlocutor?["id"].intValue
                self.senderName = generateShortName(interlocutor?["first_name"].string, last: interlocutor?["last_name"].stringValue)
                self.senderPhoto100 = interlocutor?["photo_100"].stringValue
                self.verified = interlocutor?["verified"].intValue ?? 0
                self.sex = interlocutor?["sex"].intValue ?? 0
            case .create:
                self.userId = conversation["conversation"]["peer"]["id"].intValue
                self.name = conversation["conversation"]["chat_settings"]["title"].stringValue
                self.photo100 = conversation["conversation"]["chat_settings"]["photo"]["photo_100"].stringValue
            }
            self.type = ConversationPeerType.chat.rawValue
            self.lastSeen = 0
            self.isOnline = false
            self.appId = 0
            self.isMobile = false
        }
    }
    
    func generateShortName(_ first: String?, last: String?) -> String {
        let name = "\((first ?? "") + " " + (last?.first?.string ?? "")).: "
        return name
    }
}

protocol MessageProtocol: AnyObject {
    var peerId: Int { get set }
    var date: String? { get set }
    var dateInteger: Int? { get set }
    var fromId: Int? { get set }
    var id: Int? { get set }
    var out: Int? { get set }
    var text: String? { get set }
    var conversationMessageId: Int? { get set }
    var isImportantMessage: Bool? { get set }
    var randomId: Int? { get set }
    var actionType: MessageAction.RawValue? { get set }
    var attachmentType: MessageAttachmentType.RawValue? { get set }
    var forwardMessagesCount: Int? { get set }
    var hasReplyMessage: Bool? { get set }
    var hasAttachments: Bool? { get set }
    var hasForwardedMessages: Bool? { get set }
    var isRemoved: Bool? { get set }
    var removedMessageFlag: Int? { get set }
}
