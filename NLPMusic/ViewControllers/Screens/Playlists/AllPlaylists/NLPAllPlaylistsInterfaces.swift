//
//  NLPAllPlaylistsInterfaces.swift
//  NLPMusic
//
//  Created by Ярослав Стрельников on 02.04.2022.
//  Copyright (c) 2022 Extended Team. All rights reserved.
//

import UIKit

protocol NLPAllPlaylistsWireframeInterface: WireframeInterface {
    func openPlaylist(_ playlist: Playlist)
}

protocol NLPAllPlaylistsViewInterface: ViewInterface {
    func startRefreshing()
    func endRefreshing()
    func didFinishLoad()
    func error(message: String)
    func didRemovePlaylist(playlist: Playlist)
}

protocol NLPAllPlaylistsPresenterInterface: PresenterInterface {
    var playlistItems: [Playlist] { get set }
    var nextFrom: String { get set }
    func onGetPlaylists(isPaginate: Bool) throws
    func onOpenPlaylist(_ playlist: Playlist)
    func onRemovePlaylist(playlist: Playlist) throws
    func didRemovePlaylist(playlist: Playlist)
}

protocol NLPAllPlaylistsInteractorInterface: InteractorInterface {
    func getPlaylists(isPaginate: Bool) throws
    func deletePlaylist(playlist: Playlist) throws
}
