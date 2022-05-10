//
//  RecommendationsPresenter.swift
//  NLPMusic
//
//  Created by Ярослав Стрельников on 02.04.2022.
//  Copyright (c) 2022 Extended Team. All rights reserved.
//

import Foundation

final class NLPRecommendationsPresenter {

    // MARK: - Private properties -

    private unowned let view: NLPRecommendationsViewInterface
    private let interactor: NLPRecommendationsInteractorInterface
    private let wireframe: NLPRecommendationsWireframeInterface
    
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

    init(view: NLPRecommendationsViewInterface, interactor: NLPRecommendationsInteractorInterface, wireframe: NLPRecommendationsWireframeInterface) {
        self.view = view
        self.interactor = interactor
        self.wireframe = wireframe
    }
}

// MARK: - Extensions -

extension NLPRecommendationsPresenter: NLPRecommendationsPresenterInterface {
    func onGetRecommendations() throws {
        DispatchQueue.main.async {
            self.view.startRefreshing()
        }
        try interactor.getRecommendations()
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
