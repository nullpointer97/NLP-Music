//
//  NLPAudioPresenter.swift
//  NLPMusic
//
//  Created by Ярослав Стрельников on 04.04.2022.
//  Copyright (c) 2022 Extended Team. All rights reserved.
//

import Foundation

final class NLPAudioPresenter {

    // MARK: - Private properties -

    private unowned let view: NLPAudioViewInterface
    private let interactor: NLPAudioInteractorInterface
    private let wireframe: NLPAudioWireframeInterface
    
    var isPageNeed: Bool = false
    var nextFrom: String = ""
    var audioItems: [AudioPlayerItem] {
        get {
            return view.audioItems
        }
        set {
            view.audioItems = newValue
        }
    }
    
    var vkTabBarController: NLPTabController? {
        get {
            return view.vkTabBarController
        }
    }

    // MARK: - Lifecycle -

    init(view: NLPAudioViewInterface, interactor: NLPAudioInteractorInterface, wireframe: NLPAudioWireframeInterface) {
        self.view = view
        self.interactor = interactor
        self.wireframe = wireframe
    }
}

// MARK: - Extensions -

extension NLPAudioPresenter: NLPAudioPresenterInterface {
    func onGetAudio(userId: Int, isPaginate: Bool) throws {
        DispatchQueue.main.async {
            self.view.startRefreshing()
        }
        try interactor.getAudio(userId: userId, isPaginate: isPaginate)
    }
    
    func onAddAudio(audio: AudioPlayerItem) throws {
        try interactor.addAudio(audio: audio)
    }
    
    func onRemoveAudio(audio: AudioPlayerItem) throws {
        try interactor.removeAudio(audio: audio)
    }
    
    func didRemoveAudio(audio: AudioPlayerItem) {
        DispatchQueue.main.async {
            self.view.didRemoveAudioInCache(audio: audio)
        }
    }
    
    func onOpenRecommendations() {
        wireframe.openRecommendations()
    }
    
    func onOpenFriends() {
        wireframe.openFriends()
    }
    
    func onEndRefreshing() {
        DispatchQueue.main.async {
            self.view.endRefreshing()
        }
    }

    func onDidFinishLoad() {
        DispatchQueue.main.async {
            self.view.didFinishLoad()
        }
    }

    func onError(message: String) {
        DispatchQueue.main.async {
            self.view.error(message: message)
        }
    }
}
