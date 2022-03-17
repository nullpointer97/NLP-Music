//
//  Session.swift
//  vkExtended
//
//  Created by Ярослав Стрельников on 09.11.2020.
//

import Foundation
import UIKit
import CoreStore

protocol ApiErrorExecutor {
    func captcha(rawUrlToImage: String, dismissOnFinish: Bool) throws
}

protocol SessionMaker: AnyObject {
    func session(id: String, sessionSaver: SessionSaver) -> Session
}

public enum SessionState: Int, Comparable, Codable {
    case destroyed = -1
    case initiated = 0
    case authorized = 1
    case deactivated = 8
    
    public static func == (lhs: SessionState, rhs: SessionState) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }

    public static func < (lhs: SessionState, rhs: SessionState) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

import Foundation

/// VK user session
public protocol Session: AnyObject {
    /// Internal VKExtended session identifier
    var id: String { get }
    /// Current session configuration.
    /// All requests in session inherit it
    var state: SessionState { get }
    /// Long poll client for this session
    var longPoll: LongPoll { get }
    /// token of current user
    var accessToken: Token? { get }
    
    var token: InvalidatableToken? { get }
    
    var apiErrorHandler: ApiErrorHandler? { get }
    
    /// Log in user with oAuth or VK app
    /// - parameter onSuccess: clousure which will be executed when user sucessfully logged.
    /// Returns info about logged user.
    /// - parameter onError: clousure which will be executed when logging failed.
    /// Returns cause of failure.
    func logIn(login: String, password: String, onSuccess: @escaping () -> (), onError: @escaping RequestCallbacks.Error)
    func logIn(login: String, password: String, captchaSid: String?, captchaKey: String?, onSuccess: @escaping () -> (), onError: @escaping RequestCallbacks.Error)
    func logIn(login: String, password: String, code: String?, forceSms: Int?, onSuccess: @escaping () -> (), onError: @escaping RequestCallbacks.Error)
    /// Log out user, remove all data and destroy current session
    func logOut(_ block: @escaping () -> (Void))
    func logOut()
    
    func throwIfDeactivated() throws
    func throwIfInvalidateSession() throws
}

protocol DestroyableSession: Session {
    func destroy()
    func destroy(_ block: @escaping () -> (Void))
}

public final class SessionImpl: Session, DestroyableSession, ApiErrorExecutor {
    public var state: SessionState {
        if id.isEmpty || token == nil {
            return .destroyed
        } else if token?.token != "invalidate" {
            return .authorized
        } else if ((token?.token.contains("_deactivate")) != nil) {
            return .deactivated
        } else {
            return .initiated
        }
    }
    
    public lazy var longPoll: LongPoll = {
        longPollMaker.longPoll(session: self)
    }()
    
    public internal(set) var id: String
    
    public internal(set) var token: InvalidatableToken?
    
    public var accessToken: Token? {
        return token
    }

    private unowned var longPollMaker: LongPollMaker
    private weak var sessionSaver: SessionSaver?
    private let authorizator: Authorizator
    private weak var delegate: ExtendedVKSessionDelegate?
    public var apiErrorHandler: ApiErrorHandler?
    private let gateQueue = DispatchQueue(label: "VKExtended.sessionQueue")
    private let queue = DispatchQueue(label: "VKExtended.authorizatorQueue")

    init(id: String, authorizator: Authorizator, sessionSaver: SessionSaver, longPollMaker: LongPollMaker, delegate: ExtendedVKSessionDelegate?) {
        self.id = id
        self.authorizator = authorizator
        self.longPollMaker = longPollMaker
        self.sessionSaver = sessionSaver
        self.delegate = delegate
        self.token = authorizator.getSavedToken(sessionId: id)
        self.apiErrorHandler = ApiErrorHandlerImpl(executor: self)
    }
    
    public func logIn(login: String, password: String, onSuccess: @escaping () -> (), onError: @escaping RequestCallbacks.Error) {
        gateQueue.async {
            self.authorizator.authorize(login: login, password: password, sessionId: self.id, revoke: true).done { (userId, token) in
                self.token = token
                self.updateUserId(userId: userId)
                DispatchQueue.global().async {
                    onSuccess()
                    self.delegate?.vkTokenCreated(for: self.id, info: ["userId": "\(userId)"])
                }
            }.catch { error in
                onError(error.toVK())
            }
        }
    }
    
    public func logIn(login: String, password: String, captchaSid: String?, captchaKey: String?, onSuccess: @escaping () -> (), onError: @escaping RequestCallbacks.Error) {
        gateQueue.async {
            self.authorizator.authorize(login: login, password: password, sessionId: self.id, revoke: true, captchaSid: captchaSid, captchaKey: captchaKey).done { (userId, token) in
                self.token = token
                self.updateUserId(userId: userId)
                DispatchQueue.global().async {
                    onSuccess()
                    self.delegate?.vkTokenCreated(for: self.id, info: ["userId": "\(userId)"])
                }
            }.catch { error in
                onError(error.toVK())
            }
        }
    }

    public func logIn(login: String, password: String, code: String?, forceSms: Int? = 0, onSuccess: @escaping () -> (), onError: @escaping RequestCallbacks.Error) {
        gateQueue.async {
            self.authorizator.authorize(login: login, password: password, sessionId: self.id, revoke: true, code: code, forceSms: forceSms).done { (userId, token) in
                self.token = token
                self.updateUserId(userId: userId)
                DispatchQueue.global().async {
                    onSuccess()
                    self.delegate?.vkTokenCreated(for: self.id, info: ["userId": "\(userId)"])
                }
            }.catch { error in
                onError(error.toVK())
            }
        }
    }
    
    public func logOut(_ block: @escaping () -> (Void)) {
        delegate?.vkTokenRemoved(for: id)
        destroy(block)
        async(.main) {
            var window: UIWindow?
            
            if #available(iOS 13.0, *) {
                for scene in UIApplication.shared.connectedScenes {
                    if scene == currentScene,
                       let delegate = scene.delegate as? SceneDelegate {
                        window = delegate.window
                    }
                }
            } else {
                window = (UIApplication.shared.delegate as? AppDelegate)?.window
            }
            
            guard let window = window else {
                return
            }
            
            let rootViewController = VKMNavigationController(rootViewController: LoginViewController())
            
            let transition = CATransition()
            transition.type = .push
            transition.subtype = .fromBottom
    
            window.rootViewController = rootViewController
            
            window.layer.add(transition, forKey: kCATransition)
        }
    }

    public func logOut() {
        delegate?.vkTokenRemoved(for: id)
        destroy()
        DispatchQueue.global(qos: .background).async {
            do {
                try AudioDataStackService.removeDataStack { _ in
                    print("Success")
                } failed: { error in
                    print("Error: \(error)")
                }
            } catch {
                print("Error: \(error)")
            }
            AudioService.instance.deinit()
            DispatchQueue.main.async {
                clearCache()
                guard let window = UIApplication.shared.windows.first else { return }
                
                let rootViewController = VKMNavigationController(rootViewController: LoginViewController())
                
                let transition = CATransition()
                transition.type = .push
                transition.subtype = .fromBottom
        
                window.rootViewController = rootViewController
                
                window.layer.add(transition, forKey: kCATransition)
            }
        }
    }

    private func throwIfDestroyed() throws {
        guard state > .destroyed else {
            throw VKError.sessionAlreadyDestroyed(self)
        }
    }
    
    public func throwIfDeactivated() throws {
        guard state > .authorized else {
            VK.sessions.default.logOut()
            throw VKError.userDeactivated(reason: "User deactivated")
        }
    }
    
    private func throwIfAuthorized() throws {
        guard state < .authorized else {
            throw VKError.sessionAlreadyAuthorized(self)
        }
    }
    
    private func throwIfNotAuthorized() throws {
        guard state >= .authorized else {
            throw VKError.sessionIsNotAuthorized(self)
        }
    }
    
    public func throwIfInvalidateSession() throws {
        VK.sessions.default.logOut()
        throw VKError.authorizationFailed
    }
    
    func destroy() {
        gateQueue.sync { unsafeDestroy() }
    }
    
    func destroy(_ block: @escaping () -> (Void)) {
        gateQueue.sync { unsafeDestroy(block) }
    }
    
    func captcha(rawUrlToImage: String, dismissOnFinish: Bool) throws {
        try throwIfDestroyed()
    }
    
    private func unsafeDestroy() {
        longPoll.stop()
        token = authorizator.reset(sessionId: id)
        id = ""
        updateUserId(userId: 0)
        sessionSaver?.saveState()
        sessionSaver?.removeSession()
    }
    
    private func unsafeDestroy(_ block: @escaping () -> (Void)) {
        longPoll.stop()
        token = authorizator.reset(sessionId: id)
        id = ""
        updateUserId(userId: 0)
        sessionSaver?.saveState()
        sessionSaver?.removeSession()
        block()
    }
    
    private func updateUserId(userId: Int) {
        currentUserId = userId
    }
}

struct EncodedSession: Codable {
    let isDefault: Bool
    let id: String
    let token: String
}

public protocol SessionsHolder: AnyObject {
    /// Default VK user session
    var `default`: Session { get }
    
    var all: [Session] { get }
    
    // For now VKExtended does not support multisession
    // Probably, in the future it will be done
    // If you want to use more than one session, let me know about it
    // Maybe, you make PR to VKExtended ;)
    //    func make(config: SessionConfig) -> Session
    //    var all: [Session] { get }
    //    func destroy(session: Session) throws
    //    func markAsDefault(session: Session) throws
}

protocol SessionSaver: AnyObject {
    func saveState()
    func destroy(session: Session) throws
    func removeSession()
}

public final class SessionsHolderImpl: SessionsHolder, SessionSaver {
    private unowned var sessionMaker: SessionMaker
    private let sessionsStorage: SessionsStorage
    private var sessions = NSHashTable<AnyObject>(options: .strongMemory)
    
    public var `default`: Session {
        if let realDefault = storedDefault, realDefault.state > .destroyed {
            return realDefault
        }
        
        sessions.remove(storedDefault)
        return makeSession(makeDefault: true)
    }
    
    private weak var storedDefault: Session?
    
    public var all: [Session] {
        return sessions.allObjects.compactMap { $0 as? Session }
    }
    
    init(sessionMaker: SessionMaker, sessionsStorage: SessionsStorage) {
        self.sessionMaker = sessionMaker
        self.sessionsStorage = sessionsStorage
        restoreState()
    }
    
    public func make() -> Session {
        return makeSession()
    }
    
    @discardableResult
    private func makeSession(makeDefault: Bool = false) -> Session {
        let sessionId = MD5.MD5(generatedSessionId).uppercased()
        let session = sessionMaker.session(id: sessionId, sessionSaver: self)
        
        sessions.add(session)
        
        if makeDefault {
            storedDefault = session
        }
        
        saveState()
        log("Created session with id: \(sessionId)", type: .debug)
        return session
    }
    
    private var generatedSessionId: String {
        let deviceId = UIDevice.current.identifierForVendor!.uuidString
        let randomInt = Int.random(in: 11...11).stringValue
        let sessionId = "\(deviceId)_\(randomInt)"
        return sessionId
    }
    
    public func destroy(session: Session) throws {
        if session.state == .destroyed {
            throw VKError.sessionAlreadyDestroyed(session)
        }
        
        (session as? DestroyableSession)?.destroy()
        sessions.remove(session)
    }
    
    public func markAsDefault(session: Session) throws {
        if session.state == .destroyed {
            throw VKError.sessionAlreadyDestroyed(session)
        }
        
        self.storedDefault = session
        saveState()
    }
    
    func saveState() {
        let encodedSessions = self.all.map { EncodedSession(isDefault: $0.id == storedDefault?.id, id: $0.id, token: $0.accessToken?.token ?? "invalidate") }.filter { !$0.id.isEmpty }
        
        do {
            try self.sessionsStorage.save(sessions: encodedSessions)
        }
        catch let error {
            print("VKExtended: Sessions not saved with an error: \(error)")
        }
    }
    
    private func restoreState() {
        do {
            let restored = try sessionsStorage.restore()
            
            restored.filter { !$0.id.isEmpty }.forEach { makeSession(makeDefault: $0.isDefault) }
        }
        catch let error {
            print("VKExtended: Sessions not rerstored with an error: \(error)")
        }
    }
    
    public func removeSession() {
        let encodedSessions = all.map { EncodedSession(isDefault: $0.id == storedDefault?.id, id: $0.id, token: $0.accessToken?.token ?? "invalidate") }.filter { !$0.id.isEmpty }
        
        do {
            try self.sessionsStorage.remove(sessions: encodedSessions)
            log("Remove sessions with ids: \(all.filter { !$0.id.isEmpty }.map { $0.id })", type: .debug)
        } catch {
            log("Sessions not saved with an error: \(error)", type: .error)
        }
    }
}
