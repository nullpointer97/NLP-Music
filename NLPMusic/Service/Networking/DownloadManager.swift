//
//  DownloadManager.swift
//  NLPMusic
//
//  Created by Ярослав Стрельников on 20.04.2022.
//  Copyright © 2022 NP-Team. All rights reserved.
//

import Foundation
import UIKit
import CoreStore
import RNCryptor

enum DownloadStatus {
    case none
    case inProgress
    case completed
    case failed
}

extension URLSession {
    func getSessionDescription () -> Int {
        // row id
        return Int(self.sessionDescription!)!
    }
    
    func getDebugDescription () -> Int {
        // table id
        return Int(self.debugDescription)!
    }
}

typealias ProgressHandler = (Int, Int, Float) -> ()

class DownloadManager : NSObject, URLSessionDelegate, URLSessionDownloadDelegate {
    static var shared = DownloadManager()
    var identifier: Int = -1
    var tableId: Int = -1
    var row: Int = 0
    var folderPath: String = ""
    var item: AudioPlayerItem?
    
    var operations = [Int: DownloadOperation]()
    
    /// Serial OperationQueue for downloads
    
    private let queue: OperationQueue = {
        let _queue = OperationQueue()
        _queue.name = "download"
        _queue.maxConcurrentOperationCount = 1    // I'd usually use values like 3 or 4 for performance reasons, but OP asked about downloading one at a time
        
        return _queue
    }()
    
    var onProgress : ProgressHandler? {
        didSet {
            if onProgress != nil {
                let _ = session
            }
        }
    }
    
    override init() {
        super.init()
    }
    
    lazy var session: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: "\(Bundle.main.bundleIdentifier!).background.\(UUID().uuidString)")
        
        let urlSession = URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue())
        urlSession.sessionDescription = String(identifier)
        urlSession.accessibilityHint = String(tableId)
        return urlSession
    }()

    @discardableResult
    func queueDownload(_ url: URL) -> DownloadOperation {
        let operation = DownloadOperation(session: session, url: url, item: item)
        operation.row = row
        operations[operation.task.taskIdentifier] = operation
        queue.addOperation(operation)
        return operation
    }
    
    /// Cancel all queued operations
    
    func cancelAll() {
        queue.cancelAllOperations()
    }
    
    private func calculateProgress(session : URLSession, completionHandler: @escaping (Int, Int, Float) -> ()) {
        session.getTasksWithCompletionHandler { (tasks, uploads, downloads) in
            let progress = downloads.map { (task) -> Float in
                if task.countOfBytesExpectedToReceive > 0 {
                    return Float(task.countOfBytesReceived) / Float(task.countOfBytesExpectedToReceive)
                } else {
                    return 0.0
                }
            }

            completionHandler(self.row, Int(session.accessibilityHint!)!, progress.reduce(0.0, +))
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        operations[downloadTask.taskIdentifier]?.urlSession(session, downloadTask: downloadTask, didFinishDownloadingTo: location)
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        operations[downloadTask.taskIdentifier]?.urlSession(session, downloadTask: downloadTask, didWriteData: bytesWritten, totalBytesWritten: totalBytesWritten, totalBytesExpectedToWrite: totalBytesExpectedToWrite)
        if totalBytesExpectedToWrite > 0 {
            if let onProgress = onProgress {
                calculateProgress(session: session, completionHandler: onProgress)
            }
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        debugPrint("Task completed: \(task), error: \(String(describing: error))")
    }
}

class DownloadOperation : AsynchronousOperation {
    var task: URLSessionTask!
    var item: AudioPlayerItem?
    var row: Int = 0
    
    var onProgress: ProgressHandler? {
        didSet {
            if onProgress != nil {
                
            }
        }
    }
    
    init(session: URLSession, url: URL, item: AudioPlayerItem?) {
        super.init()
        
        self.item = item
        task = session.downloadTask(with: url)
        task.resume()
    }
    
    override func cancel() {
        task.cancel()
        super.cancel()
    }
    
    override func main() {
        task.resume()
    }
    
    private func calculateProgress(session: URLSession, completionHandler: @escaping (Int, Int, Float) -> ()) {
        session.getTasksWithCompletionHandler { (tasks, uploads, downloads) in
            let progress = downloads.map { (task) -> Float in
                if task.countOfBytesExpectedToReceive > 0 {
                    return Float(task.countOfBytesReceived) / Float(task.countOfBytesExpectedToReceive)
                } else {
                    return 0.0
                }
            }
            completionHandler(self.row, Int(session.accessibilityHint!)!, progress.reduce(0.0, +))
        }
    }
}

extension DownloadOperation: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let httpResponse = downloadTask.response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode, let item = item else { return }
        var documentsDirectoryURL: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("music_cache")
        
        guard let url = URL(string: item.url) else { return }
        var destinationUrl = documentsDirectoryURL.appendingPathComponent("\(item.songName ?? "unknown").\(url.pathExtension)")

        do {
            try FileManager.default.moveItem(at: location, to: destinationUrl)

            /*
             let data = try Data(contentsOf: destinationUrl, options: [])
             let encryptFile = RNCryptor.encrypt(data: data, withPassword: "nlp_music_crypt")
             try encryptFile.write(to: destinationUrl, options: [.fileProtectionMask])
            */
            
            try AudioDataStackService.dataStack.perform { transaction in
                do {
                    _ = try transaction.importUniqueObject(Into<AudioItem>(), source: item)
                    NotificationCenter.default.post(name: NSNotification.Name("didDownloadAudio"), object: nil, userInfo: ["item": item])
                } catch {
                    print(error.localizedDescription)
                }
            }
        } catch {
            print(error)
        }
        
        state = .finished
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        if totalBytesExpectedToWrite > 0 {
            onProgress?(row, Int(session.accessibilityHint!)!, Float(totalBytesWritten)/Float(totalBytesExpectedToWrite))
            state = .executing
        }
    }
}

class AsynchronousOperation: Operation {
    
    /// State for this operation.
    
    @objc enum OperationState: Int {
        case ready
        case executing
        case finished
    }
    
    /// Concurrent queue for synchronizing access to `state`.
    
    private let stateQueue = DispatchQueue(label: Bundle.main.bundleIdentifier! + ".rw.state", attributes: .concurrent)
    
    /// Private backing stored property for `state`.
    
    private var rawState: OperationState = .ready
    
    /// The state of the operation
    
    @objc dynamic var state: OperationState {
        get { return stateQueue.sync { rawState } }
        set { stateQueue.sync(flags: .barrier) { rawState = newValue } }
    }
    
    // MARK: - Various `Operation` properties
    
    open         override var isReady:        Bool { return state == .ready && super.isReady }
    public final override var isExecuting:    Bool { return state == .executing }
    public final override var isFinished:     Bool { return state == .finished }
    
    // KVO for dependent properties
    
    open override class func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
        if ["isReady", "isFinished", "isExecuting"].contains(key) {
            return [#keyPath(state)]
        }
        
        return super.keyPathsForValuesAffectingValue(forKey: key)
    }
    
    // Start
    
    public final override func start() {
        if isCancelled {
            finish()
            return
        }
        
        state = .executing
        
        main()
    }
    
    /// Subclasses must implement this to perform their work and they must not call `super`. The default implementation of this function throws an exception.
    
    open override func main() {
        fatalError("Subclasses must implement `main`.")
    }
    
    /// Call this function to finish an operation that is currently executing
    
    public final func finish() {
        if !isFinished { state = .finished }
    }
}

extension URL {
    /// `true` is hidden (invisible) or `false` is not hidden (visible)
    var isHidden: Bool {
        get {
            return (try? resourceValues(forKeys: [.isHiddenKey]))?.isHidden == true
        }
        set {
            var resourceValues = URLResourceValues()
            resourceValues.isHidden = newValue
            do {
                try setResourceValues(resourceValues)
            } catch {
                print("isHidden error:", error)
            }
        }
    }
}
