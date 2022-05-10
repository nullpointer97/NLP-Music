//
//  AudioPlayer+Control.swift
//  AudioPlayer
//
//  Created by Kevin DELANNOY on 29/03/16.
//  Copyright © 2016 Kevin Delannoy. All rights reserved.
//

import CoreMedia
#if os(iOS) || os(tvOS)
    import UIKit
#endif

extension AudioPlayer {
    func togglePlay() {
        switch state {
        case .playing:
            pause()
        case .paused:
            resume()
        default:
            break
        }
    }
    
    /// Resumes the player.
    public func resume() {
        //Ensure pause flag is no longer set
        pausedForInterruption = false
        
        player?.rate = rate

        //We don't wan't to change the state to Playing in case it's Buffering. That
        //would be a lie.
        if !state.isPlaying && !state.isBuffering {
            state = .playing
        }
        player?.play()

        retryEventProducer.startProducingEvents()
        
        if let currentItem = currentItem {
            firstDelegate?.audioPlayer(self, willResumePlaying: currentItem)
            secondDelegate?.audioPlayer(self, willResumePlaying: currentItem)
            thirdDelegate?.audioPlayer(self, willResumePlaying: currentItem)
        }
    }
    
    public func resume(items: [AudioPlayerItem], startAtIndex index: Int = 0) {
        if !items.isEmpty {
            queue = AudioItemQueue(items: items, mode: mode)
            queue?.delegate = self
            if let realIndex = queue?.queue.firstIndex(of: items[index]) {
                queue?.nextPosition = realIndex
            }
            currentItem = queue?.nextItem()
            seek(to: Settings.lastPlayingTime)
        } else {
            stop()
            queue = nil
        }
    }

    /// Pauses the player.
    public func pause() {
        //We ensure the player actually pauses
        player?.rate = 0
        state = .paused
        player?.pause()

        retryEventProducer.stopProducingEvents()

        //Let's begin a background task for the player to keep buffering if the app is in
        //background. This will mimic the default behavior of `AVPlayer` when pausing while the
        //app is in foreground.
        backgroundHandler.beginBackgroundTask()
        
        if let currentItem = currentItem {
            firstDelegate?.audioPlayer(self, willPausePlaying: currentItem)
            secondDelegate?.audioPlayer(self, willPausePlaying: currentItem)
            thirdDelegate?.audioPlayer(self, willPausePlaying: currentItem)
        }
    }
    
    /// Starts playing the current item immediately. Works on iOS/tvOS 10+ and macOS 10.12+
    func playImmediately() {
        if #available(iOS 10.0, tvOS 10.0, OSX 10.12, *) {
            self.state = .playing
            player?.playImmediately(atRate: rate)
            
            retryEventProducer.stopProducingEvents()
            backgroundHandler.endBackgroundTask()
        }
    }

    /// Plays previous item in the queue or rewind current item.
    public func previous() {
        guard let queue = queue else { return }
        print("previous ->", queue.nextPosition)
        
        if mode.contains(.repeat) {
            let item = queue.queue[max(0, queue.nextPosition - 1)]
            queue.historic.append(item)
            print("previous (repeat) ->", queue.nextPosition)
        }
        
        if mode.contains(.repeatAll) {
            if queue.nextPosition <= 0 {
                queue.nextPosition = queue.queue.count
                print("previous (repeatAll) ->", queue.nextPosition)
            }
        }
        
        if currentItemProgression ?? 0 > 5 {
            seek(to: 0)
        } else {
            if let current = currentItem {
                let currentIndex = queue.queue.firstIndex(of: current) ?? 0
                let previousIndex = currentIndex - 1
                guard previousIndex >= 0 else {
                    return
                }
                
                queue.nextPosition = previousIndex
                let item = queue.queue[previousIndex]

                if queue.shouldConsiderItem(item: item) {
                    queue.historic.append(item)
                }
                
                currentItem = item
                print("previous ->", queue.nextPosition)
            }
        }
    }

    /// Plays the next item in the queue and if there isn't, the player will stop.
    public func nextOrStop() {
        guard let queue = queue else { return }
        
        if mode.contains(.repeat) {
            let item = queue.queue[queue.nextPosition]
            queue.historic.append(item)
            print("next (repeat) ->", queue.nextPosition)
        }
        
        if mode.contains(.repeatAll) {
            if queue.nextPosition >= queue.queue.count - 1 {
                queue.nextPosition = 0
                print("next (repeatAll) ->", queue.nextPosition)
            }
        }
        
        if let current = currentItem {
            let currentIndex = queue.queue.firstIndex(of: current) ?? 0
            let nextIndex = currentIndex + 1
            guard nextIndex < queue.queue.count else {
                return
            }
            
            let item = queue.queue[nextIndex]
            queue.nextPosition = nextIndex

            if queue.shouldConsiderItem(item: item) {
                queue.historic.append(item)
            }
            
            currentItem = item
            print("next ->", queue.nextPosition)
        }
    }
    
    public func autoNextOrStop() {
        guard let queue = queue else { return }
        print("next ->", queue.nextPosition)
        
        if mode.contains(.repeat) {
            let item = queue.queue[queue.nextPosition]
            queue.historic.append(item)
            currentItem = queue.queue[queue.nextPosition]
            print("next (repeat) ->", queue.nextPosition)
            return
        }
        
        if mode.contains(.repeatAll) {
            if queue.nextPosition >= queue.queue.count - 1 {
                queue.nextPosition = 0
                currentItem = queue.queue[queue.nextPosition]
                print("next (repeatAll) ->", queue.nextPosition)
                return
            }
        }
        
        if let current = currentItem {
            let currentIndex = queue.queue.firstIndex(of: current) ?? 0
            let nextIndex = currentIndex + 1
            guard nextIndex < queue.queue.count else {
                currentItem = nil
                return
            }
            
            let item = queue.queue[nextIndex]
            queue.nextPosition = nextIndex

            if queue.shouldConsiderItem(item: item) {
                queue.historic.append(item)
            }
            
            currentItem = item
            print("next ->", queue.nextPosition)
        }
    }

    /// Stops the player and clear the queue.
    public func stop() {
        retryEventProducer.stopProducingEvents()

        if let _ = player {
            player?.rate = 0
            player = nil
        }
        if let currentItem = currentItem {
            firstDelegate?.audioPlayer(self, willStopPlaying: currentItem)
            secondDelegate?.audioPlayer(self, willStopPlaying: currentItem)
            thirdDelegate?.audioPlayer(self, willStopPlaying: currentItem)
            self.currentItem = nil
        }
        if let _ = queue {
            queue = nil
        }

        setAudioSession(active: false)
        state = .stopped
    }
    
    func seek(to seconds: TimeInterval, completionHandler: ((Bool) -> Void)? = nil) {
        guard let completionHandler = completionHandler else {
            player?.seek(to: CMTimeMakeWithSeconds(seconds, preferredTimescale: 1000))
            return
        }
        guard player?.currentItem?.status == .readyToPlay else {
            completionHandler(false)
            return
        }
        player?.seek(to: CMTimeMakeWithSeconds(seconds, preferredTimescale: 1000)) { (finished) in
            completionHandler(finished)
        }
    }

    /// Seeks to a specific time.
    ///
    /// - Parameters:
    ///   - time: The time to seek to.
    ///   - byAdaptingTimeToFitSeekableRanges: A boolean value indicating whether the time should be adapted to current
    ///         seekable ranges in order to be bufferless.
    ///   - toleranceBefore: The tolerance allowed before time.
    ///   - toleranceAfter: The tolerance allowed after time.
    ///   - completionHandler: The optional callback that gets executed upon completion with a boolean param indicating
    ///         if the operation has finished.
    public func seek(to time: TimeInterval,
                     byAdaptingTimeToFitSeekableRanges: Bool = false,
                     toleranceBefore: CMTime = CMTime.positiveInfinity,
                     toleranceAfter: CMTime = CMTime.positiveInfinity,
                     completionHandler: ((Bool) -> Void)? = nil)
    {
        guard let earliest = currentItemSeekableRange?.earliest,
            let latest = currentItemSeekableRange?.latest else {
                //In case we don't have a valid `seekableRange`, although this *shouldn't* happen
                //let's just call `AVPlayer.seek(to:)` with given values.
                seekSafely(to: time, toleranceBefore: toleranceBefore, toleranceAfter: toleranceAfter,
                           completionHandler: completionHandler)
                return
        }

        if !byAdaptingTimeToFitSeekableRanges || (time >= earliest && time <= latest) {
            //Time is in seekable range, there's no problem here.
            seekSafely(to: time, toleranceBefore: toleranceBefore, toleranceAfter: toleranceAfter,
                 completionHandler: completionHandler)
        } else if time < earliest {
            //Time is before seekable start, so just move to the most early position as possible.
            seekToSeekableRangeStart(padding: 1, completionHandler: completionHandler)
        } else if time > latest {
            //Time is larger than possibly, so just move forward as far as possible.
            seekToSeekableRangeEnd(padding: 1, completionHandler: completionHandler)
        }
    }

    /// Seeks backwards as far as possible.
    ///
    /// - Parameter padding: The padding to apply if any.
    /// - completionHandler: The optional callback that gets executed upon completion with a boolean param indicating
    ///     if the operation has finished.
    public func seekToSeekableRangeStart(padding: TimeInterval, completionHandler: ((Bool) -> Void)? = nil) {
        guard let range = currentItemSeekableRange else {
                completionHandler?(false)
                return
        }
        let position = min(range.latest, range.earliest + padding)
        seekSafely(to: position, completionHandler: completionHandler)
    }

    /// Seeks forward as far as possible.
    ///
    /// - Parameter padding: The padding to apply if any.
    /// - completionHandler: The optional callback that gets executed upon completion with a boolean param indicating
    ///     if the operation has finished.
    public func seekToSeekableRangeEnd(padding: TimeInterval, completionHandler: ((Bool) -> Void)? = nil) {
        guard let range = currentItemSeekableRange else {
                completionHandler?(false)
                return
        }
        let position = max(range.earliest, range.latest - padding)
        seekSafely(to: position, completionHandler: completionHandler)
    }

    #if os(iOS) || os(tvOS)
    //swiftlint:disable cyclomatic_complexity
    /// Handle events received from Control Center/Lock screen/Other in UIApplicationDelegate.
    ///
    /// - Parameter event: The event received.
    public func remoteControlReceived(with event: UIEvent) {
        guard event.type == .remoteControl else {
            return
        }

        switch event.subtype {
        case .remoteControlBeginSeekingBackward:
            seekingBehavior.handleSeekingStart(player: self, forward: false)
        case .remoteControlBeginSeekingForward:
            seekingBehavior.handleSeekingStart(player: self, forward: true)
        case .remoteControlEndSeekingBackward:
            seekingBehavior.handleSeekingEnd(player: self, forward: false)
        case .remoteControlEndSeekingForward:
            seekingBehavior.handleSeekingEnd(player: self, forward: true)
        case .remoteControlNextTrack:
            nextOrStop()
        case .remoteControlPause,
             .remoteControlTogglePlayPause where state.isPlaying:
            pause()
        case .remoteControlPlay,
             .remoteControlTogglePlayPause where state.isPaused:
            resume()
        case .remoteControlPreviousTrack:
            previous()
        case .remoteControlStop:
            stop()
        default:
            break
        }
    }
    #endif
}

extension AudioPlayer {
    
    fileprivate func seekSafely(to time: TimeInterval,
                                toleranceBefore: CMTime = CMTime.positiveInfinity,
                                toleranceAfter: CMTime = CMTime.positiveInfinity,
                                completionHandler: ((Bool) -> Void)?)
    {
        guard let completionHandler = completionHandler else {
            player?.seek(to: CMTime(timeInterval: time), toleranceBefore: toleranceBefore,
                         toleranceAfter: toleranceAfter)
            // updateNowPlayingInfoCenter()
            return
        }
        guard player?.currentItem?.status == .readyToPlay else {
            completionHandler(false)
            return
        }
        player?.seek(to: CMTime(timeInterval: time), toleranceBefore: toleranceBefore, toleranceAfter: toleranceAfter,
                     completionHandler: { [weak self] finished in
                        completionHandler(finished)
                        // self?.updateNowPlayingInfoCenter()
        })
    }
}
