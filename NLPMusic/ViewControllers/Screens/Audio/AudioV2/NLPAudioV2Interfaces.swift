//
//  NLPAudioV2Interfaces.swift
//  NLPMusic
//
//  Created by Ярослав Стрельников on 04.04.2022.
//  Copyright (c) 2022 Extended Team. All rights reserved.
//

import UIKit

protocol NLPAudioV2WireframeInterface: WireframeInterface {
    func openRecommendations()
    func openFriends()
}

protocol NLPAudioV2ViewInterface: ViewInterface {
    var vkTabBarController: NLPTabController? { get }
    func didRemoveAudioInCache(audio: AudioPlayerItem)
}

protocol NLPAudioV2PresenterInterface: PresenterInterface {
    var audioItems: [AudioPlayerItem] { get set }
    var dataSource: [AudioSection]? { get set }
    var vkTabBarController: NLPTabController? { get }
    func onGetAudio(userId: Int, isPaginate: Bool) throws
    func onRemoveAudio(audio: AudioPlayerItem) throws
    func didRemoveAudio(audio: AudioPlayerItem)
    func onOpenRecommendations()
    func onOpenFriends()
    func onAddAudio(audio: AudioPlayerItem) throws
}

protocol NLPAudioV2InteractorInterface: InteractorInterface {
    func getAudio(userId: Int, isPaginate: Bool) throws
    func removeAudio(audio: AudioPlayerItem) throws
    func addAudio(audio: AudioPlayerItem) throws
}
