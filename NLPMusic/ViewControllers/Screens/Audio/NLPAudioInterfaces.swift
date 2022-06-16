//
//  NLPAudioInterfaces.swift
//  NLPMusic
//
//  Created by Ярослав Стрельников on 04.04.2022.
//  Copyright (c) 2022 Extended Team. All rights reserved.
//

import UIKit

protocol NLPAudioWireframeInterface: WireframeInterface {
    func openRecommendations()
    func openFriends()
}

protocol NLPAudioViewInterface: ViewInterface {
    var vkTabBarController: NLPTabController? { get }
    func didRemoveAudioInCache(audio: AudioPlayerItem)
}

protocol NLPAudioPresenterInterface: PresenterInterface {
    var audioItems: [AudioPlayerItem] { get set }
    var vkTabBarController: NLPTabController? { get }
    func onGetAudio(userId: Int, isPaginate: Bool) throws
    func onRemoveAudio(audio: AudioPlayerItem) throws
    func didRemoveAudio(audio: AudioPlayerItem)
    func onOpenRecommendations()
    func onOpenFriends()
    func onAddAudio(audio: AudioPlayerItem) throws
}

protocol NLPAudioInteractorInterface: InteractorInterface {
    func getAudio(userId: Int, isPaginate: Bool) throws
    func removeAudio(audio: AudioPlayerItem) throws
    func addAudio(audio: AudioPlayerItem) throws
}
