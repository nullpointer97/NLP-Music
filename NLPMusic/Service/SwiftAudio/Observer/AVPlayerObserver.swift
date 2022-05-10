//
//  AudioPlayerObserver.swift
//  SwiftAudio
//
//  Created by Jørgen Henrichsen on 09/03/2018.
//  Copyright © 2018 Jørgen Henrichsen. All rights reserved.
//

import Foundation
import AVFoundation

protocol NLPAVPlayerObserverDelegate: AnyObject {
    
    /**
     Called when the AVPlayer.status changes.
     */
    func player(statusDidChange status: AVPlayer.Status)
    
    /**
     Called when the AVPlayer.timeControlStatus changes.
     */
    func player(didChangeTimeControlStatus status: AVPlayer.TimeControlStatus)
    
}

/**
 Observing an AVPlayers status changes.
 */
class NLPAVPlayerObserver: NSObject {
    
    private static var context = 0
    private let main: DispatchQueue = .main
    
    private struct NLPAVPlayerKeyPath {
        static let status = #keyPath(AVPlayer.status)
        static let timeControlStatus = #keyPath(AVPlayer.timeControlStatus)
    }
    
    private let statusChangeOptions: NSKeyValueObservingOptions = [.new, .initial]
    private let timeControlStatusChangeOptions: NSKeyValueObservingOptions = [.new]
    private(set) var isObserving: Bool = false
    
    weak var delegate: NLPAVPlayerObserverDelegate?
    weak var player: AVPlayer? {
        willSet {
            self.stopObserving()
        }
    }
    
    deinit {
        self.stopObserving()
    }
    
    /**
     Start receiving events from this observer.
     */
    func startObserving() {
        guard let player = player else {
            return
        }
        self.stopObserving()
        self.isObserving = true
        player.addObserver(self, forKeyPath: NLPAVPlayerKeyPath.status, options: self.statusChangeOptions, context: &NLPAVPlayerObserver.context)
        player.addObserver(self, forKeyPath: NLPAVPlayerKeyPath.timeControlStatus, options: self.timeControlStatusChangeOptions, context: &NLPAVPlayerObserver.context)
    }
    
    func stopObserving() {
        guard let player = player, isObserving else {
            return
        }
        player.removeObserver(self, forKeyPath: NLPAVPlayerKeyPath.status, context: &NLPAVPlayerObserver.context)
        player.removeObserver(self, forKeyPath: NLPAVPlayerKeyPath.timeControlStatus, context: &NLPAVPlayerObserver.context)
        self.isObserving = false
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard context == &NLPAVPlayerObserver.context, let observedKeyPath = keyPath else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        
        switch observedKeyPath {
            
        case NLPAVPlayerKeyPath.status:
            self.handleStatusChange(change)
            
        case NLPAVPlayerKeyPath.timeControlStatus:
            self.handleTimeControlStatusChange(change)
            
        default:
            break
            
        }
    }
    
    private func handleStatusChange(_ change: [NSKeyValueChangeKey: Any]?) {
        let status: AVPlayer.Status
        if let statusNumber = change?[.newKey] as? NSNumber {
            status = AVPlayer.Status(rawValue: statusNumber.intValue)!
        }
        else {
            status = .unknown
        }
        delegate?.player(statusDidChange: status)
    }
    
    private func handleTimeControlStatusChange(_ change: [NSKeyValueChangeKey: Any]?) {
        let status: AVPlayer.TimeControlStatus
        if let statusNumber = change?[.newKey] as? NSNumber {
            status = AVPlayer.TimeControlStatus(rawValue: statusNumber.intValue)!
            delegate?.player(didChangeTimeControlStatus: status)
        }
    }
    
}
