//
//  NLPSearchAudioWireframe.swift
//  NLPMusic
//
//  Created by Ярослав Стрельников on 11.04.2022.
//  Copyright (c) 2022 Extended Team. All rights reserved.
//

import UIKit

final class NLPSearchAudioWireframe: BaseWireframe<NLPSearchAudioViewController> {

    // MARK: - Private properties -

    // MARK: - Module setup -

    init() {
        let moduleViewController = NLPSearchAudioViewController()
        super.init(viewController: moduleViewController)

        let interactor = NLPSearchAudioInteractor()
        let presenter = NLPSearchAudioPresenter(view: moduleViewController, interactor: interactor, wireframe: self)
        moduleViewController.presenter = presenter
        interactor.presenter = presenter
    }

}

// MARK: - Extensions -

extension NLPSearchAudioWireframe: NLPSearchAudioWireframeInterface {
}
