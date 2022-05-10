//
//  NLPPlaylistWireframe.swift
//  NLPMusic
//
//  Created by Ярослав Стрельников on 02.04.2022.
//  Copyright (c) 2022 Extended Team. All rights reserved.
//

import UIKit

final class NLPPlaylistWireframe: BaseWireframe<NLPPlaylistViewController> {

    // MARK: - Private properties -

    // MARK: - Module setup -

    init(_ playlist: Playlist) {
        let moduleViewController = NLPPlaylistViewController(playlist)
        super.init(viewController: moduleViewController)

        let interactor = NLPPlaylistInteractor()
        let presenter = NLPPlaylistPresenter(view: moduleViewController, interactor: interactor, wireframe: self)
        moduleViewController.presenter = presenter
        interactor.presenter = presenter
    }

}

// MARK: - Extensions -

extension NLPPlaylistWireframe: NLPPlaylistWireframeInterface {
}
