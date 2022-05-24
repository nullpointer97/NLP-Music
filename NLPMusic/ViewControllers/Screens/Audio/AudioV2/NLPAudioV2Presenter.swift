//
//  NLPAudioV2Presenter.swift
//  NLPMusic
//
//  Created by Ярослав Стрельников on 04.04.2022.
//  Copyright (c) 2022 Extended Team. All rights reserved.
//

import Foundation
import UIKit

struct AudioSectionItem {
    var items: [AudioPlayerItem]
    var title: String
    var image: String?
    var blockId: String
    var viewControllerToPresent: UIViewController? = nil
}

struct AudioSection {
    var items: [AudioSectionItem]
    var title: String
    var count: Int
}

final class NLPAudioV2Presenter {

    // MARK: - Private properties -

    private unowned let view: NLPAudioV2ViewInterface
    private let interactor: NLPAudioV2InteractorInterface
    private let wireframe: NLPAudioV2WireframeInterface
    
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
    
    var dataSource: [AudioSection]?
    
    var vkTabBarController: NLPTabController? {
        get {
            return view.vkTabBarController
        }
    }

    // MARK: - Lifecycle -

    init(view: NLPAudioV2ViewInterface, interactor: NLPAudioV2InteractorInterface, wireframe: NLPAudioV2WireframeInterface) {
        self.view = view
        self.interactor = interactor
        self.wireframe = wireframe
    }
}

// MARK: - Extensions -

extension NLPAudioV2Presenter: NLPAudioV2PresenterInterface {
    func onGetAudio() throws {
        DispatchQueue.main.async {
            self.view.startRefreshing()
        }
        try interactor.getAudio()
    }
    
    func onPreloadAudio() throws {
        try interactor.preloadAudio()
    }
    
    func onAddAudio(audio: AudioPlayerItem) throws {
        try interactor.addAudio(audio: audio)
    }
    
    func onRemoveAudio(audio: AudioPlayerItem) throws {
        try interactor.removeAudio(audio: audio)
    }
    
    func didRemoveAudio(audio: AudioPlayerItem) {
        DispatchQueue.main.async {
            self.view.didRemoveAudioInCache(audio: audio)
        }
    }
    
    func onOpenRecommendations() {
        wireframe.openRecommendations()
    }
    
    func onOpenFriends() {
        wireframe.openFriends()
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
