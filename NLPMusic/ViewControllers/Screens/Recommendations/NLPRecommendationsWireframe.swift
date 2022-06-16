//
//  RecommendationsWireframe.swift
//  NLPMusic
//
//  Created by Ярослав Стрельников on 02.04.2022.
//  Copyright (c) 2022 Extended Team. All rights reserved.
//

import UIKit

final class NLPRecommendationsWireframe: BaseWireframe<NLPRecommendationsViewController> {

    // MARK: - Private properties -

    // MARK: - Module setup -

    init() {
        let moduleViewController = NLPRecommendationsViewController()
        super.init(viewController: moduleViewController)

        let interactor = NLPRecommendationsInteractor()
        let presenter = NLPRecommendationsPresenter(view: moduleViewController, interactor: interactor, wireframe: self)
        moduleViewController.presenter = presenter
        interactor.presenter = presenter
    }

}

// MARK: - Extensions -

extension NLPRecommendationsWireframe: NLPRecommendationsWireframeInterface {
}
