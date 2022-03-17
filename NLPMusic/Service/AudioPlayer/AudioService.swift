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
    
    fileprivate let playerNode = AVAudioPlayerNode()
    fileprivate let audioEngine = AVAudioEngine()
    fileprivate var audioFileBuffer: AVAudioPCMBuffer?
    fileprivate var EQNode: AVAudioUnitEQ?
    
    var player: AudioPlayer?
    
    func startPlayer() {
        player = AudioPlayer()

        MPNowPlayingInfoCenter.default().nowPlayingInfo = [String: Any]()
        
        let musicFolderUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("music_cache")
        if !FileManager.default.fileExists(atPath: musicFolderUrl.path) {
            do {
                try FileManager.default.createDirectory(atPath: musicFolderUrl.path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print(error.localizedDescription)
            }
        }
        
        let frequencies: [Float] = [4, 3, 2, 2.5, -1.5, -1.5, 0, 1, 2, 3]
        
        // initial Equalizer.
        EQNode = AVAudioUnitEQ(numberOfBands: frequencies.count)
        EQNode!.globalGain = 1
        for i in 0...(EQNode!.bands.count-1) {
            EQNode!.bands[i].frequency = Float(frequencies[i])
            EQNode!.bands[i].gain = 0
            EQNode!.bands[i].bypass = false
            EQNode!.bands[i].filterType = .parametric
        }
        
        // Attach nodes to an engine.
        audioEngine.attach(EQNode!)
        audioEngine.attach(playerNode)
        
        // Connect player to the EQNode.
        let mixer = audioEngine.mainMixerNode
        audioEngine.connect(playerNode, to: EQNode!, format: mixer.outputFormat(forBus: 0))
        
        // Connect the EQNode to the mixer.
        audioEngine.connect(EQNode!, to: mixer, format: mixer.outputFormat(forBus: 0))
        
        // Schedule player to play the buffer on a loop.
        if let audioFileBuffer = audioFileBuffer {
            playerNode.scheduleBuffer(audioFileBuffer, at: nil, options: .loops, completionHandler: nil)
        }
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
    
    public func engineStart() {
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            assertionFailure("failed to audioEngine start. Error: \(error)")
        }
    }
}
