//
//  Conversation.swift
//  VKM
//
//  Created by Ярослав Стрельников on 03.03.2021.
//

import UIKit
import CoreStore
import SwiftyJSON

enum ConversationParserError: Error {
    case mismatchConversation
}

enum ConversationObjectAction {
    case update(isOut: Bool = false, isCurrentPeer: Bool = false)
    case create
}

typealias _ConversationCreater = (action: ConversationObjectAction, conversation: JSON?, interlocutor: JSON?)

final class Conversation: CoreStoreObject, ImportableUniqueObject, MessageProtocol {
    static var uniqueIDKeyPath: String {
        return #keyPath(Conversation.peerId)
    }
    
    static func uniqueID(from source: _ConversationCreater, in transaction: BaseDataTransaction) throws -> Int? {
        switch source.action {
        case .update:
            return source.conversation?["peer_id"].int
        case .create:
            return source.conversation?["conversation"]["peer"]["id"].int
        }
    }
    
    var uniqueIDValue: Int {
        get { return peerId }
        set { peerId = newValue }
    }
    
    func update(from source: _ConversationCreater, in transaction: BaseDataTransaction) throws {
        guard let conversation = source.conversation else { throw ConversationParserError.mismatchConversation }
        updateConversation(conversation, source.action)
        updateLastMessage(conversation, source.action)
        switch source.action {
        case .update:
            updateInterlocutor(conversation, source.interlocutor, ConversationPeerType.get(by: conversation["peer_id"].intValue), source.action)
        case .create:
            updateInterlocutor(conversation, source.interlocutor, ConversationPeerType.get(by: conversation["conversation"]["peer"]["id"].intValue), source.action)
        }
    }
    
    func didInsert(from source: _ConversationCreater, in transaction: BaseDataTransaction) throws {
        guard let conversation = source.conversation else { throw ConversationParserError.mismatchConversation }
        updateConversation(conversation, source.action)
        updateLastMessage(conversation, source.action)
        switch source.action {
        case .update:
            updateInterlocutor(conversation, source.interlocutor, ConversationPeerType.get(by: conversation["peer_id"].intValue), source.action)
        case .create:
            updateInterlocutor(conversation, source.interlocutor, ConversationPeerType.get(by: conversation["conversation"]["peer"]["id"].intValue), source.action)
        }
    }
    
    typealias UniqueIDType = Int
    
    typealias ImportSource = _ConversationCreater
    
    @objc
    @Field.Stored("peerId")
    var peerId: Int = 0
    
    @Field.Stored("type")
    var type: String?
    
    @Field.Stored("localId")
    var localId: Int?
    
    @Field.Stored("lastMessageId")
    var lastMessageId: Int?
    
    @Field.Stored("inRead")
    var inRead: Int?
    
    @Field.Stored("outRead")
    var outRead: Int?
    
    @Field.Stored("canWriteAllowed")
    var canWriteAllowed: Bool?
    
    @Field.Stored("canWriteReason")
    var canWriteReason: Int?
    
    @Field.Stored("majorId")
    var majorId: Int = 0
    
    @Field.Stored("minorId")
    var minorId: Int = 0
    
    @Field.Stored("isImportant")
    var isImportant: Bool?
    
    @Field.Stored("isMarkedUnread")
    var isMarkedUnread: Bool?
    
    // MARK: Chat Settings
    @Field.Stored("membersCount")
    var membersCount: Int?
    
    @Field.Stored("title")
    var title: String?

    @Field.Stored("state")
    var state: String?
    
    @Field.Stored("ownerId")
    var ownerId: Int?
    
    @Field.Stored("isGroupChannel")
    var isGroupChannel: Bool?

    // MARK: Push Settings
    @Field.Stored("disabledUntil")
    var disabledUntil: Int?
    
    @Field.Stored("disabledForever")
    var disabledForever: Bool?
    
    @Field.Stored("noSound")
    var noSound: Bool?
    
    @Field.Stored("unreadCount")
    var unreadCount: Int?
    
    @Field.Stored("isTyping")
    var isTyping: Bool?

    @Field.Stored("text")
    var text: String?
    
    // MARK: NEW FEATURES
    // MARK: Stored removing messages
    @Field.Stored("isRemovedConversation")
    var isRemovedConversation: Bool?
    
    @Field.Stored("isRemoved")
    var isRemoved: Bool?
    
    @Field.Stored("removeConversationFlag")
    var removedMessageFlag: Int?
    
    // MARK: Private conversation
    @Field.Stored("isPrivateConversation")
    var isPrivateConversation: Bool?
    
    // MARK: Last Message
    @Field.Stored("date")
    var date: String?
    
    @Field.Stored("dateInteger")
    var dateInteger: Int?
    
    @Field.Stored("fromId")
    var fromId: Int?
    
    @Field.Stored("id")
    var id: Int?
    
    @Field.Stored("out")
    var out: Int?
    
    @Field.Stored("conversationMessageId")
    var conversationMessageId: Int?
    
    @Field.Stored("isImportantMessage")
    var isImportantMessage: Bool?
    
    @Field.Stored("randomId")
    var randomId: Int?
    
    @Field.Stored("actionType")
    var actionType: MessageAction.RawValue?
    
    @Field.Stored("attachmentType")
    var attachmentType: MessageAttachmentType.RawValue?

    @Field.Stored("forwardMessagesCount")
    var forwardMessagesCount: Int?
    
    @Field.Stored("hasReplyMessage")
    var hasReplyMessage: Bool?

    @Field.Stored("hasAttachments")
    var hasAttachments: Bool?
    
    @Field.Stored("hasForwardedMessages")
    var hasForwardedMessages: Bool?
    
    @Field.Stored("userId")
    var userId: Int = 0
    
    @Field.Stored("photo100")
    var photo100: String = ""
    
    @Field.Stored("visible")
    var visible: Bool = false
    
    @Field.Stored("lastSeen")
    var lastSeen: Int = 0
    
    @Field.Stored("isOnline")
    var isOnline: Bool = false
    
    @Field.Stored("appId")
    var appId: Int = 0
    
    @Field.Stored("isMobile")
    var isMobile: Bool = false
    
    @Field.Stored("sex")
    var sex: Int = 0
    
    @Field.Stored("verified")
    var verified: Int = 0
    
    @Field.Stored("name")
    var name: String = ""
    
    @Field.Stored("imageStatusUrl")
    var imageStatusUrl: String? = ""
    
    @Field.Stored("senderId")
    var senderId: Int? = 0
    
    @Field.Stored("senderName")
    var senderName: String? = ""
    
    @Field.Stored("senderPhoto100")
    var senderPhoto100: String? = ""
    
    @Field.Stored("interlocutorType")
    var interlocutorType: ConversationPeerType.RawValue?
    
    @Field.Stored("messagesCount")
    var messagesCount: Int = 0
    
    class func typeAttachment(string: String?) -> MessageAttachmentType {
        switch string {
        case "photo":
            return .photo
        case "video":
            return .video
        case "audio":
            return .audio
        case "audio_message":
            return .audio_message
        case "doc":
            return .doc
        case "link":
            return .link
        case "market":
            return .market
        case "market_album":
            return .market_album
        case "wall":
            return .wall
        case "wall_reply":
            return .wall_reply
        case "sticker":
            return .sticker
        case "gift":
            return .gift
        case "graffiti":
            return .graffity
        case "call":
            return .call
        case "":
            return .none
        default:
            return .unknown
        }
    }
    
    func getCanWriteMessage(by reason: Int) -> String {
        switch reason {
        case 18: return "Пользователь заблокирован или удален"
        case 900: return "Пользователь в черном списке"
        case 901: return "Пользователь запретил сообщения от сообщества"
        case 902: return "Пользователь ограничил круг лиц, которые ему могут написать"
        case 915: return "В сообществе отключены сообщения"
        case 916: return "В сообществе заблокированы сообщения"
        case 917: return "Нет доступа к чату"
        case 918: return "Нет доступа к e-mail"
        case 925: return "Это канал сообщества"
        case 945: return "Беседа закрыта"
        case 203: return "Нет доступа к сообществу"
        default: return "Запрещено (неизвестный код)"
        }
    }
    
    static func messageTime(time: Int) -> String {
        let date = Date(timeIntervalSince1970: Double(time))
        let timestamp: NSNumber = NSNumber(value: date.timeIntervalSince1970)
        let seconds = timestamp.doubleValue
        let timestampDate = Date(timeIntervalSince1970: seconds)
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ru_RU")
        
        dateFormatter.dateFormat = "H:mm"
        let formatDate = dateFormatter.string(from: timestampDate)
        return formatDate
    }
    
    var conversationType: ConversationPeerType {
        switch type {
        case "user":
            return .user
        case "group":
            return .group
        case "chat":
            return .chat
        default:
            fatalError("Unknown conversation peer type")
        }
    }

    var isOutgoing: Bool {
        return out == 1 ? true : false
    }
    
    public var isMuted: Bool {
        return (disabledUntil ?? 0) != 0 || noSound ?? false
    }
    
    public var unreadStatus: ReadStatus {
        if inRead! < lastMessageId! || unreadCount! > 0 {
            return .unreadIn
        } else if outRead! < lastMessageId! {
            return .unreadOut
        } else if isMarkedUnread! {
            return .markedUnread
        } else if (inRead == lastMessageId) && (outRead == lastMessageId) {
            return .read
        } else {
            return .read
        }
    }
    
    func increaseCounter() {
        unreadCount = unreadCount ?? 0 + 1
    }
    
    func nullableCounter() {
        unreadCount = 0
    }
    
    func update(from messageEvent: EventHandler.MessageEvent) {
        text = messageEvent.text == "\r" ? "Пустое сообщение" : messageEvent.text
        if dateInteger! < messageEvent.date {
            dateInteger = messageEvent.date
            date = Conversation.messageTime(time: messageEvent.date)
        }
        if lastMessageId! < messageEvent.messageId {
            lastMessageId = messageEvent.messageId
        }
        if id! < messageEvent.messageId {
            id = messageEvent.messageId
        }
        if (messageEvent.attachments?.attaches.count ?? 0) > 0 {
            attachmentType = MessageAttachmentType.setMultiple(messageEvent.attachments?.attaches.count ?? 0)
        }
    }
    
    var isMultiple: Bool {
        for word in Localization.attachmentsString {
            guard let word = word, let type = attachmentType else { return false }
            return type.contains(word)
        }
        return false
    }
    
    static func profile(for sourseId: Int, profiles: [JSON], groups: [JSON]) -> JSON {
        let profilesOrGroups: [JSON] = sourseId >= 0 ? profiles : groups
        let normalSourseId = sourseId >= 0 ? sourseId : -sourseId
        let profileRepresenatable = profilesOrGroups.first { (myProfileRepresenatable) -> Bool in
            myProfileRepresenatable["id"].intValue == normalSourseId
        }
        return profileRepresenatable!
    }
}
