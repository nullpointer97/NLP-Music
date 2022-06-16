//
//  AudioService.swift
//  VKM
//
//  Created by Ярослав Стрельников on 24.05.2021.
//

import Foundation
import UIKit
import MediaPlayer

open class AudioService: UIResponder {
    public static let instance = AudioService()
    
    var player: AudioPlayer?
    
    func startPlayer() {
        player = AudioPlayer()

        MPNowPlayingInfoCenter.default().nowPlayingInfo = [String: Any]()
        
        var musicFolderUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("music_cache")
        if !FileManager.default.fileExists(atPath: musicFolderUrl.path) {
            do {
                try FileManager.default.createDirectory(atPath: musicFolderUrl.path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print(error.localizedDescription)
            }
        }
        musicFolderUrl.isHidden = false
    }
    
    func `deinit`() {
        player?.stop()
        player?.queue?.removeAll()
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }
    
    func addItems(_ items: [AudioPlayerItem], with remove: Bool = false) {
        if remove {
            player?.removeAll()
        }
        player?.add(items: items)
    }
}
