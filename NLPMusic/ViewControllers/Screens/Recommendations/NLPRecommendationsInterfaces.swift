//
//  RecommendationsInterfaces.swift
//  NLPMusic
//
//  Created by Ярослав Стрельников on 02.04.2022.
//  Copyright (c) 2022 Extended Team. All rights reserved.
//

import UIKit

protocol NLPRecommendationsWireframeInterface: WireframeInterface {
}

protocol NLPRecommendationsViewInterface: ViewInterface {
    var vkTabBarController: NLPTabController? { get }
}

protocol NLPRecommendationsPresenterInterface: PresenterInterface {
    var audioItems: [AudioPlayerItem] { get set }
    var vkTabBarController: NLPTabController? { get }
    func onGetRecommendations() throws
    func onAddAudio(audio: AudioPlayerItem) throws
}

protocol NLPRecommendationsInteractorInterface: InteractorInterface {
    func getRecommendations() throws
    func addAudio(audio: AudioPlayerItem) throws
}
