//
//  EventHandler.MessageEvent.swift
//  VKM
//
//  Created by Ярослав Стрельников on 05.03.2021.
//

import Foundation
import UIKit

enum SortChangeType {
    case major
    case minor
}

enum MessageReceiveType: Int {
    case receive = 4
    case edit = 5
    
    static func getType(rawValue: Int) -> Self {
        switch rawValue {
        case 4:
            return .receive
        case 5:
            return .edit
        default:
            fatalError("No type value")
        }
    }
}

struct EventHandler {
    struct MessageEvent {
        var type: MessageReceiveType
        
        var messageId: Int
        var messageFlag: Int
        var peerId: Int
        var date: Int
        var text: String
        var attachments: MessageAttach?
        var randomId: Int
        
        struct MessageAttach {
            var attachTypes = Array<String>()
            var attaches = Array<String>()
        }
    }

    struct OnlineStatusEvent {
        var isOnline: Bool
        var peerId: Int
        var number: Int
        var timeStamp: Int
        var platfotm: Int
    }
    
    struct ReadStatusEvent {
        var eventType: Int
        var peerId: Int
        var messageId: Int
    }
    
    struct TypingEvent {
        var peerId: Int
        var isTyping: Bool
    }
    
    struct NotificationEvent {
        var peerId: Int
        var disabledUntil: Int
        var noSound: Bool
    }
    
    struct SortingEvent {
        struct MajorIdEvent {
            var peerId: Int
            var majorId: Int
        }
        
        struct MinorIdEvent {
            var peerId: Int
            var minorId: Int
        }
    }
}
