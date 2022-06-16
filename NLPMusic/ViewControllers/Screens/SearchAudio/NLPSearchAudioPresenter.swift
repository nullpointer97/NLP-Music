//
//  NLPSearchAudioPresenter.swift
//  NLPMusic
//
//  Created by Ярослав Стрельников on 11.04.2022.
//  Copyright (c) 2022 Extended Team. All rights reserved.
//

import Foundation

final class NLPSearchAudioPresenter {

    // MARK: - Private properties -

    private unowned let view: NLPSearchAudioViewInterface
    private let interactor: NLPSearchAudioInteractorInterface
    private let wireframe: NLPSearchAudioWireframeInterface
    
    var isPageNeed: Bool = false
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

    init(view: NLPSearchAudioViewInterface, interactor: NLPSearchAudioInteractorInterface, wireframe: NLPSearchAudioWireframeInterface) {
        self.view = view
        self.interactor = interactor
        self.wireframe = wireframe
    }
}

// MARK: - Extensions -

extension NLPSearchAudioPresenter: NLPSearchAudioPresenterInterface {
    func onSearchAudio(byKeyword keyword: String, isPaginate: Bool) throws {
        DispatchQueue.main.async {
            self.view.startRefreshing()
        }
        try interactor.searchAudio(byKeyword: keyword, isPaginate: isPaginate)
    }
    
    func onAddAudio(audio: AudioPlayerItem) throws {
        try interactor.addAudio(audio: audio)
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
