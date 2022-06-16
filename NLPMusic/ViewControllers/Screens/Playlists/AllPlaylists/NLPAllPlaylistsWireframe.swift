//
//  NLPAllPlaylistsWireframe.swift
//  NLPMusic
//
//  Created by Ярослав Стрельников on 02.04.2022.
//  Copyright (c) 2022 Extended Team. All rights reserved.
//

import UIKit

final class NLPAllPlaylistsWireframe: BaseWireframe<NLPAllPlaylistsViewController> {

    // MARK: - Private properties -

    // MARK: - Module setup -

    init(isOnlyAlbums: Bool) {
        let moduleViewController = NLPAllPlaylistsViewController(isOnlyAlbums: isOnlyAlbums)
        super.init(viewController: moduleViewController)

        let interactor = NLPAllPlaylistsInteractor()
        let presenter = NLPAllPlaylistsPresenter(view: moduleViewController, interactor: interactor, wireframe: self)
        moduleViewController.presenter = presenter
        interactor.presenter = presenter
    }

}

// MARK: - Extensions -

extension NLPAllPlaylistsWireframe: NLPAllPlaylistsWireframeInterface {
    func openPlaylist(_ playlist: Playlist) {
        let playlistController = NLPPlaylistWireframe(playlist).viewController
        navigationController?.pushViewController(playlistController, animated: true)
    }
}
