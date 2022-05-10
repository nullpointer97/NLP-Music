//
//  MPNowPlayingInfoCenter+AudioItem.swift
//  AudioPlayer
//
//  Created by Kevin DELANNOY on 27/03/16.
//  Copyright © 2016 Kevin Delannoy. All rights reserved.
//

import MediaPlayer

extension MPNowPlayingInfoCenter {
    /// Updates the MPNowPlayingInfoCenter with the latest information on a `AudioItem`.
    ///
    /// - Parameters:
    ///   - item: The item that is currently played.
    ///   - duration: The item's duration.
    ///   - progression: The current progression.
    ///   - playbackRate: The current playback rate.
    func ap_update(with item: AudioPlayerItem, duration: TimeInterval?, progression: TimeInterval?, playbackRate: Float) {
        getData(from: URL(string: item.albumThumb600)) { [weak self] data, response, error in
            guard let self = self else { return }
            if let data = data {
                DispatchQueue.main.async {
                    self.nowPlayingInfo?[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: .custom(600, 600)) { size in
                        if let image = UIImage(data: data) {
                            return image
                        } else {
                            return UIImage(named: "playlist_outline_56") ?? UIImage()
                        }
                    }
                }
            } else {
                let image = UIImage(named: "playlist_outline_56") ?? UIImage()
                self.nowPlayingInfo?[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: .custom(600, 600)) { size in
                    return image
                }
            }
            if let title = item.title {
                self.nowPlayingInfo?[MPMediaItemPropertyTitle] = title
            }
            if let albumName = item.albumName {
                self.nowPlayingInfo?[MPMediaItemPropertyAlbumTitle] = albumName
            }
            
            if let artist = item.artist {
                self.nowPlayingInfo?[MPMediaItemPropertyArtist] = artist
            }
            if let duration = duration {
                self.nowPlayingInfo?[MPMediaItemPropertyPlaybackDuration] = duration
            }
            if let progression = progression {
                self.nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = progression
            }
            self.nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackRate] = playbackRate
        }
    }
    
    private func getData(from url: URL?, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        guard let url = url else {
            completion(nil, nil, "No URL")
            return
        }

        URLSession.shared.dataTask(with: url, completionHandler: completion).resume()
    }
}
