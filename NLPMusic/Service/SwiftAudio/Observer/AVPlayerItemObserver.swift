//
//  AVPlayerItemObserver.swift
//  SwiftAudio
//
//  Created by Jørgen Henrichsen on 28/07/2018.
//

import Foundation
import AVFoundation

protocol NLPAVPlayerItemObserverDelegate: AnyObject {
    
    /**
     Called when the observed item updates the duration.
     */
    func item(didUpdateDuration duration: Double)
    
}

/**
 Observing an AVPlayers status changes.
 */
class NLPAVPlayerItemObserver: NSObject {
    
    private static var context = 0
    private let main: DispatchQueue = .main
    
    private struct NLPAVPlayerItemKeyPath {
        static let duration = #keyPath(AVPlayerItem.duration)
        static let loadedTimeRanges = #keyPath(AVPlayerItem.loadedTimeRanges)
    }
    
    private(set) var isObserving: Bool = false
    
    private(set) weak var observingItem: AVPlayerItem?
    weak var delegate: NLPAVPlayerItemObserverDelegate?
    
    deinit {
        stopObservingCurrentItem()
    }
    
    /**
     Start observing an item. Will remove self as observer from old item, if any.
     
     - parameter item: The player item to observe.
     */
    func startObserving(item: AVPlayerItem) {
        self.stopObservingCurrentItem()
        self.isObserving = true
        self.observingItem = item
        item.addObserver(self, forKeyPath: NLPAVPlayerItemKeyPath.duration, options: [.new], context: &NLPAVPlayerItemObserver.context)
        item.addObserver(self, forKeyPath: NLPAVPlayerItemKeyPath.loadedTimeRanges, options: [.new], context: &NLPAVPlayerItemObserver.context)
    }
    
    func stopObservingCurrentItem() {
        guard let observingItem = observingItem, isObserving else {
            return
        }
        observingItem.removeObserver(self, forKeyPath: NLPAVPlayerItemKeyPath.duration, context: &NLPAVPlayerItemObserver.context)
        observingItem.removeObserver(self, forKeyPath: NLPAVPlayerItemKeyPath.loadedTimeRanges, context: &NLPAVPlayerItemObserver.context)
        self.isObserving = false
        self.observingItem = nil
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard context == &NLPAVPlayerItemObserver.context, let observedKeyPath = keyPath else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        
        switch observedKeyPath {
        case NLPAVPlayerItemKeyPath.duration:
            if let duration = change?[.newKey] as? CMTime {
                self.delegate?.item(didUpdateDuration: duration.seconds)
            }
        
        case NLPAVPlayerItemKeyPath.loadedTimeRanges:
            if let ranges = change?[.newKey] as? [NSValue], let duration = ranges.first?.timeRangeValue.duration {
                self.delegate?.item(didUpdateDuration: duration.seconds)
            }
        default: break
            
        }
    }
    
}
