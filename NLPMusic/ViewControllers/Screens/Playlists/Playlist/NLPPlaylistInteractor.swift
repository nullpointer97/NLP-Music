//
//  NLPPlaylistInteractor.swift
//  NLPMusic
//
//  Created by Ярослав Стрельников on 02.04.2022.
//  Copyright (c) 2022 Extended Team. All rights reserved.
//

import Foundation
import Alamofire
import MaterialComponents

final class NLPPlaylistInteractor {
    weak var presenter: NLPPlaylistPresenterInterface?
}

// MARK: - Extensions -

extension NLPPlaylistInteractor: NLPPlaylistInteractorInterface {
    func getPlaylists(isPaginate: Bool = false, playlistId: Int) throws {
        var parametersAudio: Parameters = [
            "user_id" : currentUserId,
            "playlist_id" : playlistId,
            "count" : 300,
            "offset": isPaginate ? (presenter?.audioItems.count ?? 0) : 0
        ]
        
        try ApiV2.method(.getAudio, parameters: &parametersAudio, apiVersion: "5.90").done { result in
            
            self.presenter?.isPageNeed = result["response"]["count"].intValue > self.presenter?.audioItems.count ?? 0
            
            print("Debug:", result["response"]["count"].intValue, self.presenter?.audioItems.count ?? 0)
            
            let items = result["response"]["items"].arrayValue
            
            if isPaginate {
                self.presenter?.audioItems.append(contentsOf: items.compactMap { AudioPlayerItem(fromJSON: $0) }.uniqued())
            } else {
                self.presenter?.audioItems.removeAll()
                self.presenter?.audioItems.insert(contentsOf: items.compactMap { AudioPlayerItem(fromJSON: $0) }.uniqued(), at: 0)
            }
        }.ensure {
            self.presenter?.onDidFinishLoad()
        }.catch { error in
            self.presenter?.onError(message: "Произошла ошибка при загрузке\n\(error.toVK().toApi()?.message ?? "")")
        }
    }
    
    func addAudio(audio: AudioPlayerItem) throws {
        var parametersAudio: Parameters = [
            "audio_id" : audio.id,
            "owner_id" : audio.ownerId
        ]
        
        try ApiV2.method(.addAudio, parameters: &parametersAudio, apiVersion: .defaultApiVersion).done { result in
            DispatchQueue.main.async { [self] in
                let audioViewController = (presenter?.vkTabBarController?.viewControllers?.first as? NLPMNavigationController)?.viewControllers.first as? NLPAudioViewController
                guard audioViewController?.userId == currentUserId else { return }
                audioViewController?.audioItems.insert(audio, at: 0)
                audioViewController?.tableView.insertRows(at: [IndexPath(row: 0, section: 1)], with: .left)
            }
        }.catch { error in
            self.presenter?.onError(message: "Произошла ошибка при добавлении")
        }
    }
}
