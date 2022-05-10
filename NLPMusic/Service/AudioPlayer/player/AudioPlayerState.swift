//
//  AudioPlayerState.swift
//  AudioPlayer
//
//  Created by Kevin DELANNOY on 11/03/16.
//  Copyright © 2016 Kevin Delannoy. All rights reserved.
//

import Foundation

/// The possible errors an `AudioPlayer` can fail with.
///
/// - maximumRetryCountHit: The player hit the maximum retry count.
/// - foundationError: The `AVPlayer` failed to play.
/// - itemNotConsideredPlayable: The current item that should be played is considered unplayable.
/// - noItemsConsideredPlayable: The queue doesn't contain any item that is considered playable.
public enum AudioPlayerError: Error, CustomStringConvertible {
    case maximumRetryCountHit
    case foundationError(Error)
    case itemNotConsideredPlayable
    case noItemsConsideredPlayable
    
    public var description: String {
        switch self {
        case .maximumRetryCountHit:
            return "Плеер достиг максимального количества повторных попыток."
        case .foundationError(let error):
            return error.localizedDescription
        case .itemNotConsideredPlayable:
            return "Текущий элемент, который должен быть воспроизведен, считается невоспроизводимым."
        case .noItemsConsideredPlayable:
            return "Очередь не содержит ни одного предмета, который считается воспроизводимым."
        }
    }
}

/// `AudioPlayerState` defines 4 state an `AudioPlayer` instance can be in.
///
/// - buffering: The player is buffering data before playing them.
/// - playing: The player is playing.
/// - paused: The player is paused.
/// - stopped: The player is stopped.
/// - waitingForConnection: The player is waiting for internet connection.
/// - failed: An error occured. It contains AVPlayer's error if any.
public enum AudioPlayerState {
    case buffering
    case playing
    case paused
    case stopped
    case waitingForConnection
    case failed(AudioPlayerError)

    /// A boolean value indicating is self = `buffering`.
    var isBuffering: Bool {
        if case .buffering = self {
            return true
        }
        return false
    }

    /// A boolean value indicating is self = `playing`.
    var isPlaying: Bool {
        if case .playing = self {
            return true
        }
        return false
    }

    /// A boolean value indicating is self = `paused`.
    var isPaused: Bool {
        if case .paused = self {
            return true
        }
        return false
    }

    /// A boolean value indicating is self = `stopped`.
    var isStopped: Bool {
        if case .stopped = self {
            return true
        }
        return false
    }

    /// A boolean value indicating is self = `waitingForConnection`.
    var isWaitingForConnection: Bool {
        if case .waitingForConnection = self {
            return true
        }
        return false
    }

    /// A boolean value indicating is self = `failed`.
    var isFailed: Bool {
        if case .failed = self {
            return true
        }
        return false
    }

    /// The error if self = `failed`.
    var error: AudioPlayerError? {
        if case .failed(let error) = self {
            return error
        }
        return nil
    }
}

// MARK: - Equatable

extension AudioPlayerState: Equatable {}

public func == (lhs: AudioPlayerState, rhs: AudioPlayerState) -> Bool {
    if (lhs.isBuffering && rhs.isBuffering) || (lhs.isPlaying && rhs.isPlaying) ||
        (lhs.isPaused && rhs.isPaused) || (lhs.isStopped && rhs.isStopped) ||
        (lhs.isWaitingForConnection && rhs.isWaitingForConnection) {
        return true
    }
    if let e1 = lhs.error, let e2 = rhs.error {
        switch (e1, e2) {
        case (.maximumRetryCountHit, .maximumRetryCountHit):
            return true
        case (.foundationError, .foundationError):
            return true
        default:
            return false
        }
    }
    return false
}
