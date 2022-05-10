//
//  NLPPlaylistPresenter.swift
//  NLPMusic
//
//  Created by Ярослав Стрельников on 02.04.2022.
//  Copyright (c) 2022 Extended Team. All rights reserved.
//

import Foundation

final class NLPPlaylistPresenter {

    // MARK: - Private properties -

    private unowned let view: NLPPlaylistViewInterface
    private let interactor: NLPPlaylistInteractorInterface
    private let wireframe: NLPPlaylistWireframeInterface
    
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

    init(view: NLPPlaylistViewInterface, interactor: NLPPlaylistInteractorInterface, wireframe: NLPPlaylistWireframeInterface) {
        self.view = view
        self.interactor = interactor
        self.wireframe = wireframe
    }
}

// MARK: - Extensions -

extension NLPPlaylistPresenter: NLPPlaylistPresenterInterface {
    func onGetPlaylists(isPaginate: Bool = false, playlistId: Int) throws {
        DispatchQueue.main.async {
            self.view.startRefreshing()
        }
        try interactor.getPlaylists(isPaginate: isPaginate, playlistId: playlistId)
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
