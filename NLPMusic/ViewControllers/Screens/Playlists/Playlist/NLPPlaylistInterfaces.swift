//
//  NLPPlaylistInterfaces.swift
//  NLPMusic
//
//  Created by Ярослав Стрельников on 02.04.2022.
//  Copyright (c) 2022 Extended Team. All rights reserved.
//

import UIKit

protocol NLPPlaylistWireframeInterface: WireframeInterface {
}

protocol NLPPlaylistViewInterface: ViewInterface {
    var vkTabBarController: NLPTabController? { get }
}

protocol NLPPlaylistPresenterInterface: PresenterInterface {
    var audioItems: [AudioPlayerItem] { get set }
    var vkTabBarController: NLPTabController? { get }
    func onGetPlaylists(isPaginate: Bool, playlistId: Int) throws
    func onAddAudio(audio: AudioPlayerItem) throws
}

protocol NLPPlaylistInteractorInterface: InteractorInterface {
    func getPlaylists(isPaginate: Bool, playlistId: Int) throws
    func addAudio(audio: AudioPlayerItem) throws
}
