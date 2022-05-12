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
}

// MARK: - Extensions -

extension NLPAudioV2Interactor: NLPAudioV2InteractorInterface {
    func getSection(_ sectionHandler: @escaping ((String) -> ())) {
        var parametersAudio: Parameters = [:]
        
        do {
            try ApiV2.method("catalog.getAudio", parameters: &parametersAudio, apiVersion: "5.171").done { result in
                let sections = result["response"]["catalog"]["sections"].arrayValue
                self.presenter?.audioItems.removeAll()
                sectionHandler(sections[1]["id"].stringValue)
            }.catch { error in
                self.presenter?.onError(message: "Произошла ошибка при загрузке\n\(error.toVK().toApi()?.message ?? "")")
                self.presenter?.onDidFinishLoad()
                self.presenter?.dataSource = [
                    AudioSection(items: [
                        AudioSectionItem(items: [], title: "Сохраненные аудиозаписи", image: "download_outline_32", blockId: "")
                    ], title: "", count: 0)
                ]
                sectionHandler("")
            }
        } catch {
            self.presenter?.dataSource = [
                AudioSection(items: [
                    AudioSectionItem(items: [], title: "Сохраненные аудиозаписи", image: "download_outline_32", blockId: "")
                ], title: "", count: 0)
            ]
            sectionHandler("")
        }
    }
    
    func getAudio(userId: Int, isPaginate: Bool = false) throws {
        getSection { sectionId in
            var parametersAudio: Parameters = isPaginate ? ["section_id" : sectionId, "start_from": self.startFrom] : ["section_id" : sectionId]
            
            do {
                try ApiV2.method("catalog.getSection", parameters: &parametersAudio, apiVersion: "5.171").done { result in
                    let items = result["response"]
                    let lastPlayingBlock = items["section"]["blocks"].arrayValue[0]
                    let playlistBlock = items["section"]["blocks"].arrayValue[3]
                    
                    self.presenter?.dataSource = [
                        AudioSection(items: [
                            AudioSectionItem(items: [], title: lastPlayingBlock["layout"]["title"].stringValue, image: "history_backward_outline_28", blockId: lastPlayingBlock["actions"].arrayValue[0]["section_id"].stringValue),
                            AudioSectionItem(items: [], title: playlistBlock["layout"]["title"].stringValue, image: "playlist_outline_28", blockId: playlistBlock["actions"].arrayValue[0]["section_id"].stringValue),
                            AudioSectionItem(items: [], title: "Сохраненная музыка", image: "download_outline_32", blockId: "")
                        ], title: "", count: 0),
                        AudioSection(items: [
                            AudioSectionItem(items: [], title: "Перемешать все", image: "shuffle-2", blockId: "")
                        ], title: "", count: 0)
                    ]
                    
                    let audioBlock = items["section"]["blocks"].arrayValue.filter { $0["data_type"].stringValue == "music_audios" && $0["layout"]["name"].stringValue == "list" }[0]

                    try self.getBlock(sectionId: audioBlock["id"].stringValue)
                    
                    if !audioBlock["next_from"].stringValue.isEmpty {
                        DispatchQueue.global(qos: .userInteractive).asyncAfter(deadline: .now() + 2) {
                            do {
                                try self.getBlock(sectionId: audioBlock["id"].stringValue, startFrom: audioBlock["next_from"].stringValue)
                            } catch {
                                self.presenter?.onError(message: "Произошла ошибка при загрузке")
                            }
                        }
                    }
                }.catch { error in
                    self.presenter?.onError(message: "Произошла ошибка при загрузке\n\(error.toVK().toApi()?.message ?? "")")
                }
            } catch {
                self.presenter?.onError(message: "Произошла ошибка при загрузке")
            }
        }
    }
    
    private func getBlock(sectionId: String, startFrom: String = "") throws {
        var parametersAudio: Parameters = !startFrom.isEmpty ? ["section_id" : sectionId, "start_from": startFrom] : ["section_id" : sectionId]
        
        try ApiV2.method("catalog.getSection", parameters: &parametersAudio, requestMethod: .get, apiVersion: "5.171").done { response in
            let section = response["response"]["section"]
            
            try self.getAudiosByIds(audios: section["blocks"][0]["audios_ids"].arrayValue.compactMap { $0.stringValue })
        }.catch { err in
            self.presenter?.onError(message: "Произошла ошибка при загрузке\n\(err.toVK().toApi()?.message ?? "")")
        }
    }
    
    private func getAudiosByIds(audios: [String]) throws {
        var parameters: Parameters = ["audios": audios]
        try ApiV2.method("audio.getById", parameters: &parameters, requestMethod: .get, apiVersion: "5.171").done { response in
            let audios = response["response"].arrayValue
            self.presenter?.audioItems.insert(contentsOf: audios.compactMap { AudioPlayerItem(fromJSON: $0) }.uniqued(), at: self.presenter?.audioItems.count ?? 0)
            
            guard let dataSource = self.presenter?.dataSource else { return }
            
            if dataSource.indices.contains(2) {
                self.presenter?.dataSource?[2] = AudioSection(items: [
                    AudioSectionItem(items: self.presenter?.audioItems ?? [], title: "", image: nil, blockId: ""),
                ], title: "Аудиозаписи", count: (self.presenter?.audioItems ?? []).count)
            } else {
                self.presenter?.dataSource?.append([AudioSection(items: [
                    AudioSectionItem(items: self.presenter?.audioItems ?? [], title: "Треки", image: nil, blockId: ""),
                ], title: "Аудиозаписи", count: (self.presenter?.audioItems ?? []).count)])
            }
        }.ensure {
            self.presenter?.onDidFinishLoad()
        }.catch { err in
            self.presenter?.onError(message: "Произошла ошибка при загрузке\n\(err.toVK().toApi()?.message ?? "")")
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
                guard audioViewController?.userId == currentUserId else { return }
                audioViewController?.audioItems.insert(audio, at: 0)
                audioViewController?.tableView.insertRows(at: [IndexPath(row: 0, section: 1)], with: .left)
            }
        }.catch { error in
            self.presenter?.onError(message: "Произошла ошибка при добавлении\n\(error.toVK().toApi()?.message ?? "")")
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
            self.presenter?.onError(message: "Произошла ошибка при удалении\n\(error.toVK().toApi()?.message ?? "")")
        }
    }
}
