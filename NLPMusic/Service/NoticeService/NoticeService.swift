//
//  NoticeService.swift
//  vkExtended
//
//  Created by Ярослав Стрельников on 11.01.2021.
//

import Foundation
import UIKit
import SwiftyJSON

extension Notice.Names {
    static let removeConversation = Notice.Name<NoticeLongPollEvent>(.onRemoveConversation)
    
    static let messagesReceived = Notice.Name<NoticeLongPollEvent>(.onMessagesReceived)
    
    static let restoreMessage = Notice.Name<NoticeLongPollEvent>(.onResetMessageFlags)
    static let removeMessage = Notice.Name<NoticeLongPollEvent>(.onSetMessageFlags)
    static let editMessage = Notice.Name<NoticeLongPollEvent>(.onMessagesEdited)
    static let readMessage = Notice.Name<NoticeLongPollEvent>(.onMessagesRead)
    
    static let typing = Notice.Name<NoticeLongPollEvent>(.onTyping)
    static let changeNotificationSettings = Notice.Name<NoticeLongPollEvent>(.onNotificationSettingsChanged)
    
    static let changeOnline = Notice.Name<NoticeLongPollEvent>(.onChangeOnline)
    
    static let sessionLogin = Notice.Name<NoticeSession>(.onLogin)
    static let sessionLogout = Notice.Name<NoticeSession>(.onLogout)
    
    static let appActive = Notice.Name<NoticeService>(.onAppActive)
    static let appBackground = Notice.Name<NoticeService>(.onAppBackground)
    static let appForeground = Notice.Name<NoticeService>(.onAppForeground)
    
    static let majorIdChanged = Notice.Name<NoticeLongPollEvent>(.onMajorIdChanged)
    static let minorIdChanged = Notice.Name<NoticeLongPollEvent>(.onMinorIdChanged)
    
    static let audioForIndexPlaying = Notice.Name<NoticeAudioEvent>(.onPlayerStart)
}

struct NoticeService { }

struct NoticeSession {
    let sessionId: String
    let userId: Int?
}

struct NoticeLongPollEvent {
    let eventType: Any
}

struct NoticeAudioEvent {
    let newItem: AudioPlayerItem?
    let oldItem: AudioPlayerItem?
}
