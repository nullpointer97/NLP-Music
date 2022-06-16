import Foundation
import SwiftyJSON
import CoreStore
import PromiseKit

protocol LongPollTaskMaker: AnyObject {
    func longPollTask(session: Session?, data: LongPollTaskData) -> LongPollTask
    func longPollTask(data: LongPollTaskData) -> LongPollTask
}

protocol LongPollMaker: AnyObject {
    func longPoll(session: Session) -> LongPoll
}

public enum LongPollVersion: String {
    static let latest = LongPollVersion.third

    case zero = "0"
    case first = "1"
    case second = "2"
    case third = "3"
}

/// Long poll client
public protocol LongPoll {
    /// Is long poll can handle events
    var isActive: Bool { get }
    
    /// Start recieve long poll events
    /// parameters onReceiveEvents: clousure ehich executes when long poll recieve set of events
    func start(version: LongPollVersion, onReceiveEvents: @escaping ([LongPollEvent]) -> ())
    
    /// Stop recieve long poll events
    func stop()
}

extension LongPoll {
    func start(version: LongPollVersion = .latest, onReceiveEvents: @escaping ([LongPollEvent]) -> ()) {
        start(version: version, onReceiveEvents: onReceiveEvents)
    }
}

public final class LongPollImpl: NSObject, LongPoll {
    
    private weak var session: Session?
    private weak var operationMaker: LongPollTaskMaker?
    private let connectionObserver: ConnectionObserver?
    private let getInfoDelay: TimeInterval
    
    private let synchronyQueue = DispatchQueue.global(qos: .userInteractive)
    private let updatingQueue: OperationQueue
    
    private let onDisconnected: (() -> ())?
    private let onConnected: (() -> ())?
    
    public var isActive: Bool
    private var isConnected = false
    private var onReceiveEvents: (([LongPollEvent]) -> ())?
    private var taskData: LongPollTaskData?
    private var version: LongPollVersion = .first
    
    init(
        session: Session?,
        operationMaker: LongPollTaskMaker,
        connectionObserver: ConnectionObserver?,
        getInfoDelay: TimeInterval,
        onConnected: (() -> ())? = nil,
        onDisconnected: (() -> ())? = nil
        ) {
        self.isActive = false
        self.session = session
        self.operationMaker = operationMaker
        self.connectionObserver = connectionObserver
        self.getInfoDelay = getInfoDelay
        self.onConnected = onConnected
        self.onDisconnected = onDisconnected
        
        self.updatingQueue = {
            let queue = OperationQueue()
            queue.maxConcurrentOperationCount = 1
            return queue
        }()
    }
    
    public func start(version: LongPollVersion, onReceiveEvents: @escaping ([LongPollEvent]) -> ()) {
        synchronyQueue.sync {
            guard !self.isActive else { return }
            
            self.onReceiveEvents = onReceiveEvents
            self.isActive = true
            self.setUpConnectionObserver()
        }
    }
    
    public func stop() {
        synchronyQueue.sync {
            guard self.isActive else { return }
            
            self.isActive = false
            self.updatingQueue.cancelAllOperations()
        }
    }
    
    private func setUpConnectionObserver() {
        connectionObserver?.subscribe(object: self, callbacks: (onConnect: { [weak self] in
            guard let self = self else { return }
            self.onConnect()
            log("Longpoll onConnect", type: .debug)
        }, onDisconnect: { [weak self] in
            guard let self = self else { return }
            self.onDisconnect()
            log("Longpoll onDisconnect", type: .debug)
        }))
    }
    
    private func onConnect() {
        synchronyQueue.async {
            guard !self.isConnected else { return }
            self.isConnected = true

            guard self.isActive else { return }
            self.onConnected?()
            
            if self.taskData != nil {
                self.startUpdating()
            }
        }
    }
    
    private func onDisconnect() {
        synchronyQueue.async {
            guard self.isConnected else { return }
            
            self.isConnected = false
            
            guard self.isActive else { return }
            self.updatingQueue.cancelAllOperations()
            self.onDisconnected?()
        }
    }
    
    private func startUpdating() {
        updatingQueue.cancelAllOperations()
        
        guard isConnected, let data = taskData else { return }
        
        guard let operation = operationMaker?.longPollTask(session: session, data: data) else { return }
        updatingQueue.addOperation(operation.toOperation())
    }

    private func handleError(_ error: LongPollTaskError) {
        switch error {
        case .unknown:
            onReceiveEvents?([.forcedStop])
        case .historyMayBeLost:
            onReceiveEvents?([.historyMayBeLost])
        case .connectionInfoLost:
            break
        }
    }
    
    deinit {
        connectionObserver?.unsubscribe(object: self)
    }
}
extension LongPollImpl {
    @objc func onForegroundApp(notification: Notification) {
        self.onConnect()
    }
    
    @objc func onActiveApp(notification: Notification) {
        self.onDisconnect()
    }
}
