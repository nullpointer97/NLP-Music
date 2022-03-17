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
        if let title = item.title {
            nowPlayingInfo?[MPMediaItemPropertyTitle] = title
        }
        if let albumName = item.albumName {
            nowPlayingInfo?[MPMediaItemPropertyAlbumTitle] = albumName
        }
        
        if let artist = item.artist {
            nowPlayingInfo?[MPMediaItemPropertyArtist] = artist
        }
        if let duration = duration {
            nowPlayingInfo?[MPMediaItemPropertyPlaybackDuration] = duration
        }
        if let progression = progression {
            nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = progression
        }
        nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackRate] = playbackRate
        
        if let url = URL(string: item.albumThumb600) {
            getData(from: url) { data, response, error in
                guard let data = data, error == nil else { return }
                
                DispatchQueue.main.async() { [weak self] in
                    self?.nowPlayingInfo?[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: .custom(600, 600)) { size in
                        if let image = UIImage(data: data) {
                            return image
                        } else {
                            return UIImage(named: "missing_song_artwork_generic_proxy") ?? UIImage()
                        }
                    }
                }
            }
        } else {
            let image = UIImage(named: "missing_song_artwork_generic_proxy") ?? UIImage()
            nowPlayingInfo?[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: .custom(600, 600)) { size in
                return image
            }
        }
    }
    
    private func getData(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        URLSession.shared.dataTask(with: url, completionHandler: completion).resume()
    }
}
