//
//  NLPAudioV2Interactor.swift
//  NLPMusic
//
//  Created by Ярослав Стрельников on 04.04.2022.
//  Copyright (c) 2022 Extended Team. All rights reserved.
//

import Foundation
import Alamofire

final class NLPAudioV2Interactor {
    weak var presenter: NLPAudioV2PresenterInterface?
    var startFrom = ""
    var audioBlockId: String = ""
}

// MARK: - Extensions -

extension NLPAudioV2Interactor: NLPAudioV2InteractorInterface {
    func getAudio() throws {
        do {
            if let path = Bundle.main.path(forResource: "OfficialProfileGetter", ofType: "txt") {
                let code = try String(contentsOfFile: path, encoding: .utf8).replacingOccurrences(of: "INSERT_USER_ID", with: currentUserId.stringValue)
                
                var execParams: Parameters = ["code": code]
                
                try ApiV2.method("execute", parameters: &execParams).done { response in
                    let blocks = response["response"]["blocks"].arrayValue[0]

                    let recentBlock = blocks["recents"]
                    let playlistsBlock = blocks["playlists"]
                    let audioBlock = blocks["audios"]
                    
                    self.presenter?.audioItems = audioBlock["audios"].arrayValue.compactMap { AudioPlayerItem(fromJSON: $0) }.uniqued()
                    self.presenter?.dataSource = [
                        AudioSection(items: [
                            AudioSectionItem(items: [], title: .localized(.recentTitle), image: "history_backward_outline_28", blockId: recentBlock["block_id"].stringValue),
                            AudioSectionItem(items: [], title: .localized(.playlistsTitle), image: "playlist_outline_28", blockId: playlistsBlock["block_id"].stringValue),
                            AudioSectionItem(items: [], title: .localized(.albumsTitle), image: "vinyl_outline_28", blockId: playlistsBlock["block_id"].stringValue),
                            AudioSectionItem(items: [], title: .localized(.savedMusicTitle), image: "download_outline_32", blockId: "")
                        ], title: "", count: 0),
                        AudioSection(items: [
                            AudioSectionItem(items: [], title: .localized(.shuffle), image: "shuffle-2", blockId: "")
                        ], title: "", count: 0),
                        AudioSection(items: [
                            AudioSectionItem(items: self.presenter?.audioItems ?? [], title: "", image: nil, blockId: audioBlock["block_id"].stringValue),
                        ], title: .localized(.audiosTitle), count: (self.presenter?.audioItems ?? []).count)
                    ]
                    self.startFrom = audioBlock["next_from"].stringValue
                    self.audioBlockId = audioBlock["block_id"].stringValue
                    
                    try self.preloadAudio()
                }.ensure {
                    self.presenter?.onDidFinishLoad()
                }.catch { err in
                    self.presenter?.dataSource = [
                        AudioSection(items: [
                            AudioSectionItem(items: [], title: .localized(.savedMusicTitle), image: "download_outline_32", blockId: "")
                        ], title: "", count: 0)
                    ]
                    self.presenter?.onError(message: "\(String.localized(.loadingError))\n\(err.toVK().toApi()?.message ?? "")")
                }
            }
        } catch {
            self.presenter?.dataSource = [
                AudioSection(items: [
                    AudioSectionItem(items: [], title: .localized(.savedMusicTitle), image: "download_outline_32", blockId: "")
                ], title: "", count: 0)
            ]
        }
    }
    
    func preloadAudio() throws {
        presenter?.isPageNeed = false

        guard !startFrom.isEmpty else {
            return
        }
        do {
            var execParams: Parameters = ["block_id": audioBlockId, "start_from": startFrom]
            
            try ApiV2.method("catalog.getBlockItems", parameters: &execParams).done { response in
                let audioBlock = response["response"]["audios"]
                
                self.presenter?.audioItems.insert(contentsOf: audioBlock.arrayValue.compactMap { AudioPlayerItem(fromJSON: $0) }.uniqued(), at: self.presenter?.audioItems.count ?? 0)
                
                guard let dataSource = self.presenter?.dataSource else { return }
                
                if dataSource.indices.contains(2) {
                    self.presenter?.dataSource?[2] = AudioSection(items: [
                        AudioSectionItem(items: self.presenter?.audioItems ?? [], title: "", image: nil, blockId: ""),
                    ], title: .localized(.audiosTitle), count: (self.presenter?.audioItems ?? []).count)
                } else {
                    self.presenter?.dataSource?.append([AudioSection(items: [
                        AudioSectionItem(items: self.presenter?.audioItems ?? [], title: "", image: nil, blockId: ""),
                    ], title: .localized(.audiosTitle), count: (self.presenter?.audioItems ?? []).count)])
                }
                self.startFrom = response["response"]["block"]["next_from"].stringValue
            }.ensure {
                self.presenter?.onDidFinishLoad()
                self.presenter?.isPageNeed = !self.startFrom.isEmpty
            }.catch { err in
                self.presenter?.onError(message: "\(String.localized(.loadingError))\n\(err.toVK().toApi()?.message ?? "")")
            }
        } catch {
            self.presenter?.onError(message: error.localizedDescription)
        }
    }
    
    func addAudio(audio: AudioPlayerItem) throws {
        var parametersAudio: Parameters = [
            "audio_id" : audio.id,
            "owner_id" : audio.ownerId
        ]
        
        try ApiV2.method(.addAudio, parameters: &parametersAudio, apiVersion: .defaultApiVersion).done { result in
            DispatchQueue.main.async { [self] in
                let navigationController = presenter?.vkTabBarController?.viewControllers?.first as? NLPMNavigationController
                let audioViewController = navigationController?.viewControllers.first as? NLPAudioV2ViewController
                audioViewController?.presenter.dataSource?[2].items[0].items.insert(audio, at: 0)
                audioViewController?.tableView.insertRows(at: [IndexPath(row: 0, section: 2)], with: .left)
            }
        }.catch { error in
            self.presenter?.onError(message: "\(String.localized(.addError))\n\(error.toVK().toApi()?.message ?? "")")
        }
    }
    
    func removeAudio(audio: AudioPlayerItem) throws {
        var parametersAudio: Parameters = [
            "audio_id" : audio.id,
            "owner_id" : audio.ownerId
        ]
        
        try ApiV2.method(.deleteAudio, parameters: &parametersAudio, apiVersion: .defaultApiVersion).done { result in
            guard result["response"].intValue == 1 else { return }
            self.presenter?.didRemoveAudio(audio: audio)
        }.catch { error in
            self.presenter?.onError(message: "\(String.localized(.deleteError))\n\(error.toVK().toApi()?.message ?? "")")
        }
    }
}
