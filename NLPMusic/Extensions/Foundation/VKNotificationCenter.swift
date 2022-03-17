//
//  VKNotificationCenter.swift
//  vkExtended
//
//  Created by Ярослав Стрельников on 30.10.2020.
//

import Foundation

protocol VKNotificationCenter {
    func addObserver(forName name: NSNotification.Name?, object obj: Any?, queue: OperationQueue?, using block: @escaping (Notification) -> Swift.Void) -> NSObjectProtocol
    func removeObserver(_ observer: Any)
}

extension NotificationCenter: VKNotificationCenter {}
