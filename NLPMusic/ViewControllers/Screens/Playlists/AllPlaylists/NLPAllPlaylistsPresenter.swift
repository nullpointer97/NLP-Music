//
//  NLPAllPlaylistsPresenter.swift
//  NLPMusic
//
//  Created by Ярослав Стрельников on 02.04.2022.
//  Copyright (c) 2022 Extended Team. All rights reserved.
//

import Foundation

final class NLPAllPlaylistsPresenter {

    // MARK: - Private properties -

    private unowned let view: NLPAllPlaylistsViewInterface
    private let interactor: NLPAllPlaylistsInteractorInterface
    private let wireframe: NLPAllPlaylistsWireframeInterface
    
    var playlistItems: [Playlist] = []
    var isPageNeed: Bool = false
    var nextFrom: String = ""

    // MARK: - Lifecycle -

    init(view: NLPAllPlaylistsViewInterface, interactor: NLPAllPlaylistsInteractorInterface, wireframe: NLPAllPlaylistsWireframeInterface) {
        self.view = view
        self.interactor = interactor
        self.wireframe = wireframe
    }
}

// MARK: - Extensions -

extension NLPAllPlaylistsPresenter: NLPAllPlaylistsPresenterInterface {
    func onGetPlaylists(isOnlyAlbums: Bool, isPaginate: Bool = false) throws {
        DispatchQueue.main.async {
            self.view.startRefreshing()
        }
        try interactor.getPlaylists(isOnlyAlbums: isOnlyAlbums, isPaginate: isPaginate)
    }
    
    func onOpenPlaylist(_ playlist: Playlist) {
        wireframe.openPlaylist(playlist)
    }
    
    func onRemovePlaylist(playlist: Playlist) throws {
        try interactor.deletePlaylist(playlist: playlist)
    }
    
    func didRemovePlaylist(playlist: Playlist) {
        DispatchQueue.main.async {
            self.view.didRemovePlaylist(playlist: playlist)
        }
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
