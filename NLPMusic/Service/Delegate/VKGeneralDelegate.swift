//
//  VKGeneralDelegate.swift
//  vkExtended
//
//  Created by Ярослав Стрельников on 09.11.2020.
//

import Foundation
import OneSignal

class VKGeneralDelegate: NSObject {
    deinit {
        VK.release()
    }

    override init() {
        super.init()
        VK.setUp(appId: Constants.appId, delegate: self)
        guard VK.sessions.default.state == .authorized else { return }
        
        OneSignal.setExternalUserId("\(currentUserId)")
        OneSignal.sendTag("user_id", value: "\(currentUserId)")
    }
}
extension VKGeneralDelegate: ExtendedVKDelegate {
    func vkNeedsScopes(for sessionId: String) -> String {
        return "notify,friends,photos,audio,video,docs,status,notes,pages,wall,groups,messages,offline,notifications"
    }
    
    public func vkTokenCreated(for sessionId: String, info: [String: String]) {
        if let userId = info["userId"] {
            OneSignal.setExternalUserId(userId)
            OneSignal.sendTag("user_id", value: userId)
        }
    }
    
    public func vkTokenUpdated(for sessionId: String, info: [String: String]) {
        if let userId = info["userId"] {
            OneSignal.setExternalUserId(userId)
            OneSignal.sendTag("user_id", value: userId)
        }
    }
    
    public func vkTokenRemoved(for sessionId: String) {
        let sessionNotice = NoticeSession(sessionId: sessionId, userId: nil)
        Notice.Center.default.post(name: .sessionLogin, with: sessionNotice)
    }
}
