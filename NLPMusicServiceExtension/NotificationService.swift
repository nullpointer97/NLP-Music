//
//  NotificationService.swift
//  VKMusicServiceExtension
//
//  Created by Ярослав Стрельников on 07.02.2022.
//  Copyright © 2022 NP-Team. All rights reserved.
//

import UserNotifications
import OneSignal
import Sentry

class NotificationService: UNNotificationServiceExtension {
    
    var contentHandler: ((UNNotificationContent) -> Void)?
    var receivedRequest: UNNotificationRequest!
    var bestAttemptContent: UNMutableNotificationContent?
    
    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.receivedRequest = request
        self.contentHandler = contentHandler
        self.bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        if let bestAttemptContent = bestAttemptContent {
            print(bestAttemptContent.userInfo)
            
            if request.content.categoryIdentifier == "HEADPHONE_NOTIFICATION" {
                UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [request.identifier])
            }
            
            if let custom = bestAttemptContent.userInfo["custom"] as? [AnyHashable: Any] {
                if let a = custom["a"] as? [AnyHashable: Any], let appLock = a["app_locked"] as? String {
                    if let userDefaults = UserDefaults(suiteName: "group.ru.npteam.vkmusic.onesignal") {
                        userDefaults.set(appLock.boolValue, forKey: "_isAppLocked")
                    }
                }
            }
            
            OneSignal.didReceiveNotificationExtensionRequest(self.receivedRequest, with: bestAttemptContent, withContentHandler: self.contentHandler)
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
            OneSignal.serviceExtensionTimeWillExpireRequest(self.receivedRequest, with: self.bestAttemptContent)
            contentHandler(bestAttemptContent)
        }
    }
}

extension String {
    var boolValue: Bool {
        if lowercased() == "true" || lowercased() == "yes" || lowercased() == "1" {
            return true
        } else if lowercased() == "false" || lowercased() == "no" || lowercased() == "0" {
            return false
        } else {
            return false
        }
    }
}
