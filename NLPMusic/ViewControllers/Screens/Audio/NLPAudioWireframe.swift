//
//  NLPAudioWireframe.swift
//  NLPMusic
//
//  Created by Ярослав Стрельников on 04.04.2022.
//  Copyright (c) 2022 Extended Team. All rights reserved.
//

import UIKit

final class NLPAudioWireframe: BaseWireframe<NLPAudioViewController> {

    // MARK: - Private properties -

    // MARK: - Module setup -

    init() {
        let moduleViewController = NLPAudioViewController()
        super.init(viewController: moduleViewController)

        let interactor = NLPAudioInteractor()
        let presenter = NLPAudioPresenter(view: moduleViewController, interactor: interactor, wireframe: self)
        moduleViewController.presenter = presenter
        interactor.presenter = presenter
    }

}

// MARK: - Extensions -

extension NLPAudioWireframe: NLPAudioWireframeInterface {
    func openRecommendations() {
        let controller = NLPRecommendationsWireframe().viewController
        navigationController?.pushViewController(controller, animated: true)
    }
    
    func openFriends() {
        let controller = NLPFriendsViewController()
        navigationController?.pushViewController(controller, animated: true)
    }
}
