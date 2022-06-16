//
//  Dependencies.swift
//  vkExtended
//
//  Created by Ярослав Стрельников on 09.11.2020.
//

import Foundation
import UIKit

protocol Dependencies:
    DependenciesHolder,
    TokenMaker,
    SessionMaker,
    LongPollTaskMaker,
    LongPollMaker { }

protocol DependenciesHolder: SessionsHolderHolder, AuthorizatorHolder {
    init(appId: String, delegate: ExtendedVKDelegate?, bundleName: String?, configPath: String?)
}

extension DependenciesHolder {
    init(appId: String, delegate: ExtendedVKDelegate?) {
        self.init(appId: appId, delegate: delegate, bundleName: nil, configPath: nil)
    }
}

protocol SessionsHolderHolder: AnyObject {
    var sessionsHolder: SessionsHolder & SessionSaver { get }
}

protocol AuthorizatorHolder: AnyObject {
    var authorizator: Authorizator { get }
}

typealias VKStoryboard = UIStoryboard

final class DependenciesImpl: Dependencies {
    private let appId: String
    private weak var delegate: ExtendedVKDelegate?
    private let customBundleName: String?
    private let customConfigPath: String?
    
    private let longPollTaskTimeout: TimeInterval = 30
    private let uiSyncQueue = DispatchQueue(label: "VKExtended.uiSyncQueue")
    
    private lazy var connectionObserver: ConnectionObserver? = {
        guard let reachability = Reachability() else { return nil }
        
        #if os(iOS)
            let appStateCenter = NotificationCenter.default
            let activeNotificationName = UIApplication.didBecomeActiveNotification
            let inactiveNotificationName = UIApplication.didEnterBackgroundNotification
        #elseif os(macOS)
            let appStateCenter = NSWorkspace.shared.notificationCenter
            let activeNotificationName = NSWorkspace.willSleepNotification
            let inactiveNotificationName = NSWorkspace.didWakeNotification
        #endif
        
        return ConnectionObserverImpl(
            appStateCenter: appStateCenter,
            reachabilityCenter: NotificationCenter.default,
            reachability: reachability,
            activeNotificationName: activeNotificationName,
            inactiveNotificationName: inactiveNotificationName,
            reachabilityNotificationName: ReachabilityChangedNotification
        )
    }()
    
    init(appId: String, delegate: ExtendedVKDelegate?, bundleName: String?, configPath: String?) {
        self.appId = appId
        self.delegate = delegate
        self.customBundleName = bundleName
        self.customConfigPath = configPath
    }
    
    lazy var sessionsHolder: SessionsHolder & SessionSaver = {
        atomicSessionHolder.modify {
            $0 ?? SessionsHolderImpl(
                sessionMaker: self,
                sessionsStorage: self.sessionsStorage
            )
        }
        
        guard let holder = atomicSessionHolder.unwrap() else {
            fatalError("Holder was not created")
        }
        
        return holder
    }()

    private var atomicSessionHolder = Atomic<(SessionsHolder & SessionSaver)?>(nil)
    
    lazy var sessionsStorage: SessionsStorage = {
        SessionsStorageImpl(
            fileManager: FileManager(),
            bundleName: self.bundleName,
            configName: self.customConfigPath ?? "VKExtendedState"
        )
    }()
    
    private lazy var bundleName: String = {
        customBundleName ?? Bundle.main.infoDictionary?[String(kCFBundleNameKey)] as? String ?? "VKExtended"
    }()
    
    func longPoll(session: Session) -> LongPoll {
        return LongPollImpl(session: session, operationMaker: self, connectionObserver: connectionObserver, getInfoDelay: 30)
    }
    
    func longPollTask(data: LongPollTaskData) -> LongPollTask {
        return LongPollTaskImpl(delayOnError: 3, data: data)
    }
    
    func session(id: String, sessionSaver: SessionSaver) -> Session {
        return SessionImpl(
            id: id,
            authorizator: sharedAuthorizator,
            sessionSaver: sessionSaver,
            longPollMaker: self,
            delegate: delegate
        )
    }
    
    var authorizator: Authorizator {
        get { return sharedAuthorizator }
        set { sharedAuthorizator = newValue }
    }
    
    private lazy var sharedAuthorizator: Authorizator = {
        let tokenStorage = TokenStorageImpl(serviceKey: self.bundleName + "_Token")
        
        return AuthorizatorImpl(appId: self.appId, delegate: self.delegate, tokenStorage: tokenStorage, tokenMaker: self)
    }()
    
    func longPollTask(session: Session?, data: LongPollTaskData) -> LongPollTask {
        return LongPollTaskImpl(delayOnError: longPollTaskTimeout, data: data)
    }
    
    func token(token: String) -> InvalidatableToken {
        return TokenImpl(token: token)
    }
}
