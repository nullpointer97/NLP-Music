//
//  NLPAudioInteractor.swift
//  NLPMusic
//
//  Created by Ярослав Стрельников on 04.04.2022.
//  Copyright (c) 2022 Extended Team. All rights reserved.
//

import Foundation
import Alamofire

final class NLPAudioInteractor {
    weak var presenter: NLPAudioPresenterInterface?
}

// MARK: - Extensions -

extension NLPAudioInteractor: NLPAudioInteractorInterface {
    func getAudio(userId: Int, isPaginate: Bool = false) throws {
        var parametersAudio: Parameters = [
            "user_id" : userId,
            "count" : 300,
            "offset": isPaginate ? (self.presenter?.audioItems.count ?? 0) : 0
        ]
        
        try ApiV2.method(.getAudio, parameters: &parametersAudio, apiVersion: .defaultApiVersion).done { result in
            let items = result["response"]["items"].arrayValue
            
            if isPaginate {
                self.presenter?.audioItems.insert(contentsOf: items.compactMap { AudioPlayerItem(fromJSON: $0) }.uniqued(), at: self.presenter?.audioItems.count ?? 0)
            } else {
                self.presenter?.audioItems.insert(contentsOf: items.compactMap { AudioPlayerItem(fromJSON: $0) }.uniqued(), at: 0)
            }
            
            self.presenter?.isPageNeed = result["response"]["count"].intValue > self.presenter?.audioItems.count ?? 0
//            self.presenter?.vkTabBarController?.playerViewController.queueItems = self.presenter?.audioItems ?? []
        }.ensure {
            self.presenter?.onDidFinishLoad()
        }.catch { error in
            self.presenter?.onError(message: "\(String.localized(.loadingError))\n\(error.toVK().toApi()?.message ?? "")")
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
