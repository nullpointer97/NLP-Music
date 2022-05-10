//
//  RecommendationsInteractor.swift
//  NLPMusic
//
//  Created by Ярослав Стрельников on 02.04.2022.
//  Copyright (c) 2022 Extended Team. All rights reserved.
//

import Foundation
import Alamofire
import UIKit
import MaterialComponents

final class NLPRecommendationsInteractor {
    weak var presenter: NLPRecommendationsPresenterInterface?
}

// MARK: - Extensions -

extension NLPRecommendationsInteractor: NLPRecommendationsInteractorInterface {
    func getRecommendations() throws {
        var parametersAudio: Parameters = [:]
        
        try ApiV2.method(.getRecommendations, parameters: &parametersAudio, apiVersion: .defaultApiVersion).done { result in
            let items = result["response"]["items"].arrayValue
            
            self.presenter?.audioItems.removeAll()
            self.presenter?.audioItems.append(contentsOf: items.compactMap { AudioPlayerItem(fromJSON: $0) }.uniqued())
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
                let navigationController = presenter?.vkTabBarController?.viewControllers?.first as? NLPMNavigationController
                let audioViewController = navigationController?.viewControllers.first as? NLPAudioViewController
                guard audioViewController?.userId == currentUserId else { return }
                audioViewController?.audioItems.insert(audio, at: 0)
                audioViewController?.tableView.insertRows(at: [IndexPath(row: 0, section: 1)], with: .left)
            }
        }.catch { error in
            self.presenter?.onError(message: "Произошла ошибка при добавлении")
        }
    }
}
