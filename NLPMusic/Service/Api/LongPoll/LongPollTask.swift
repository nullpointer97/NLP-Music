import Foundation
import SwiftyJSON
import PromiseKit

protocol LongPollTask: OperationConvertible {}

final class LongPollTaskImpl: Operation, LongPollTask {
    private let server: String
    private var startTs: String
    private let lpKey: String
    private let delayOnError: TimeInterval
    private let onResponse: ([JSON]) -> ()
    private let onError: (LongPollTaskError) -> ()
    private let semaphore = DispatchSemaphore(value: 0)
    private let repeatQueue = DispatchQueue.global(qos: .utility)
    
    private let reachability = Reachability()
    private var promise = Promise()
    
    init(delayOnError: TimeInterval, data: LongPollTaskData) {
        self.server = data.server
        self.lpKey = data.lpKey
        self.startTs = data.startTs
        self.delayOnError = delayOnError
        self.onResponse = data.onResponse
        self.onError = data.onError
    }
    
    override func main() {
        update(ts: startTs)
        semaphore.wait()
    }
    
    private func update(ts: String) {
        guard !isCancelled else { return }
    }
    
    func handleError(code: Int, response: JSON) {
        log("LongPoll error with code \(code)", type: .error)
        switch code {
        case 1:
            guard let newTs = response["ts"].string else {
                onError(.unknown)
                semaphore.signal()
                return
            }
            
            onError(.historyMayBeLost)
            
            repeatQueue.async { [weak self] in
                self?.update(ts: newTs)
            }
        case 2, 3:
            onError(.connectionInfoLost)
            semaphore.signal()
        default:
            onError(.unknown)
            semaphore.signal()
        }
    }
    
    override func cancel() {
        super.cancel()
        semaphore.signal()
    }
}

extension LongPollTaskImpl {
    func networkIsReachable() -> Promise<Void> {
        guard promise.isResolved else { return promise }

        promise = Promise { seal in
            switch reachability?.currentReachabilityStatus {
            case .none:
                seal.reject(ReachabilityError.FailedToCreateWithHostname(""))
            case .some(let status):
                switch status {
                case .notReachable:
                    seal.reject(ReachabilityError.FailedToCreateWithHostname(""))
                case .reachableViaWiFi:
                    seal.fulfill(())
                case .reachableViaWWAN:
                    seal.fulfill(())
                }
            }
        }
        
        return promise
     }
}

struct LongPollTaskData {
    let server: String
    let startTs: String
    let startPts: String
    let lpKey: String
    let onResponse: ([JSON]) -> ()
    let onError: (LongPollTaskError) -> ()
}

enum LongPollTaskError {
    case unknown
    case historyMayBeLost
    case connectionInfoLost
}
