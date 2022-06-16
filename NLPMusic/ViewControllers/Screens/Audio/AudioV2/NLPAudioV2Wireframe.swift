//
//  NLPAudioV2Wireframe.swift
//  NLPMusic
//
//  Created by Ярослав Стрельников on 04.04.2022.
//  Copyright (c) 2022 Extended Team. All rights reserved.
//

import UIKit

final class NLPAudioV2Wireframe: BaseWireframe<NLPAudioV2ViewController> {

    // MARK: - Private properties -

    // MARK: - Module setup -

    init() {
        let moduleViewController = NLPAudioV2ViewController()
        super.init(viewController: moduleViewController)

        let interactor = NLPAudioV2Interactor()
        let presenter = NLPAudioV2Presenter(view: moduleViewController, interactor: interactor, wireframe: self)
        moduleViewController.presenter = presenter
        interactor.presenter = presenter
    }

}

// MARK: - Extensions -

extension NLPAudioV2Wireframe: NLPAudioV2WireframeInterface {
    func openRecommendations() {
        let controller = NLPRecommendationsWireframe().viewController
        navigationController?.pushViewController(controller, animated: true)
    }
    
    func openFriends() {
        let controller = NLPFriendsViewController()
        navigationController?.pushViewController(controller, animated: true)
    }
}
