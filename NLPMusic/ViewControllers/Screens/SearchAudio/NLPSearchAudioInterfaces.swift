//
//  NLPSearchAudioInterfaces.swift
//  NLPMusic
//
//  Created by Ярослав Стрельников on 11.04.2022.
//  Copyright (c) 2022 Extended Team. All rights reserved.
//

import UIKit

protocol NLPSearchAudioWireframeInterface: WireframeInterface {
}

protocol NLPSearchAudioViewInterface: ViewInterface {
    var vkTabBarController: NLPTabController? { get }
}

protocol NLPSearchAudioPresenterInterface: PresenterInterface {
    var audioItems: [AudioPlayerItem] { get set }
    var vkTabBarController: NLPTabController? { get }
    func onAddAudio(audio: AudioPlayerItem) throws
    func onSearchAudio(byKeyword keyword: String, isPaginate: Bool) throws
}

protocol NLPSearchAudioInteractorInterface: InteractorInterface {
    func addAudio(audio: AudioPlayerItem) throws
    func searchAudio(byKeyword keyword: String, isPaginate: Bool) throws
}
