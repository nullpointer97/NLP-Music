//
//  Message.swift
//  VKM
//
//  Created by Ярослав Стрельников on 28.04.2021.
//

import Foundation
import CoreStore
import SwiftyJSON

struct PlaceSender: SenderType {
    var senderId: String
    var displayName: String
    var avatar: UIImage?
}

typealias _MessageCreater = (action: ConversationObjectAction, message: JSON)

final class Message: CoreStoreObject, ImportableUniqueObject, MessageType {
    var sender: SenderType {
        return PlaceSender(senderId: "\(fromId ?? currentUserId)", displayName: "", avatar: nil)
    }
    
    var messageId: String {
        return "\(id)"
    }
    
    var sentDate: Date {
        return Date(timeIntervalSince1970: Double(date ?? 0))
    }
    
    var kind: MessageKind {
        return .text(getText())
    }
    
    static var uniqueIDKeyPath: String {
        return #keyPath(Message.id)
    }
    
    static func uniqueID(from source: _MessageCreater, in transaction: BaseDataTransaction) throws -> Int? {
        return source.message["id"].int
    }
    
    var uniqueIDValue: Int {
        get { return id }
        set { id = newValue }
    }
    
    func update(from source: _MessageCreater, in transaction: BaseDataTransaction) throws {
        let message = source.message
        id = source.message["id"].intValue
        date = message["date"].int
        fromId = message["from_id"].int
        out = message["out"].int
        peerId = message["peer_id"].int
        text = message["text"].string
        conversationMessageId = message["conversation_message_id"].int
        randomId = message["random_id"].int
    }
    
    func didInsert(from source: _MessageCreater, in transaction: BaseDataTransaction) throws {
        let message = source.message
        id = source.message["id"].intValue
        date = message["date"].int
        fromId = message["from_id"].int
        out = message["out"].int
        peerId = message["peer_id"].int
        text = message["text"].string
        conversationMessageId = message["conversation_message_id"].int
        randomId = message["random_id"].int
    }
    
    typealias UniqueIDType = Int
    
    typealias ImportSource = _MessageCreater
    
    @objc
    @Field.Stored("id")
    var id: Int = 0
    
    @Field.Stored("date")
    var date: Int?
    
    @Field.Stored("fromId")
    var fromId: Int?
    
    @Field.Stored("out")
    var out: Int?
    
    @Field.Stored("peerId")
    var peerId: Int?
    
    @Field.Stored("text")
    var text: String?
    
    @Field.Stored("conversationMessageId")
    var conversationMessageId: Int?
    
    @Field.Stored("randomId")
    var randomId: Int?
    
    private func getText() -> String {
        guard let text = text, !text.isEmpty else { return "Сообщение без текста" }
        return text
    }
}

final class MessageDataStackService: NSObject {
    static var peerId = 0 {
        didSet {
            try! self.messages.refetch(
                From<Message>()
                    .orderBy(.descending(\.$date))
                    .tweak {
                        $0.predicate = NSPredicate(format: "peerId == %@", argumentArray: [peerId])
                    }
            )
        }
    }
    
    static let messages: ListPublisher<Message> = {
        let peerId = UserDefaults.standard.integer(forKey: "__chat_peer_id__")
        let list = dataStack.publishList(
            From<Message>(),
            Tweak { request in
                request.predicate = NSPredicate(format: "peerId == %@", argumentArray: [peerId])
            },
            OrderBy<Message>(.descending("date"))
        )
        return list
    }()
    
    static let dataStack: DataStack = {
        let dataStack = DataStack(CoreStoreSchema(modelVersion: "V1", entities: [Entity<Message>("Message")]))
        try! dataStack.addStorageAndWait(SQLiteStore(fileName: "Message.sqlite", localStorageOptions: .recreateStoreOnModelMismatch))
        return dataStack
    }()
    
    static func removeDataStack(success: @escaping ((Message.Type) -> Void), failed: @escaping ((CoreStoreError) -> Void)) throws {
        dataStack.perform { transaction in
            try transaction.deleteAll(From<Message>())
        } completion: { result in
            switch result {
            case .success:
                success(Message.self)
            case .failure(let coreStoreError):
                failed(coreStoreError)
            }
        }
    }
}
