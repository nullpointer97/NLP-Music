//
//  VKTabController.swift
//  vkmusic
//
//  Created by Ярослав Стрельников on 23.02.2022.
//  Copyright © 2022 NP-Team. All rights reserved.
//

import UIKit
import SPAlert
import Kingfisher

class VKTabController: UITabBarController {
    var observables: [Observable] = []
    var playerViewController = BetaPlayerViewController()
    
    var audioItems: [AudioPlayerItem] = []
    
    init() {
        super.init(nibName: nil, bundle: nil)
        AudioService.instance.player?.secondDelegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tabBar.tintColor = .getAccentColor(fromType: .common)
        tabBar.barStyle = .default
        
        popupInteractionStyle = .snap
        popupBar.barStyle = Settings.smallPlayer ? .compact : .prominent
        popupBar.progressViewStyle = Settings.progressDown ? .bottom : .top
        popupBar.progressView.progressTintColor = .getAccentColor(fromType: .common)
        popupContentView.popupCloseButtonStyle = .chevron
        
        playerViewController.popupItem.image = .init(named: "missing_song_artwork_generic_proxy")
        playerViewController.vkTabBarController = self
        
        observables.append(UserDefaults.standard.observe(Bool.self, key: "_smallPlayer") {
            let isSmall = $0
            
            UIView.transition(with: self.view, duration: 0.2) {
                self.popupBar.barStyle = !isSmall ? .prominent : .compact
                self.popupBar.layoutIfNeeded()
                if let currentItem = AudioService.instance.player?.currentItem {
                    if let subtitle = currentItem.subtitle, !subtitle.isEmpty {
                    self.playerViewController.popupItem.attributedTitle = NSAttributedString(string: currentItem.title ?? "", attributes: [.font: UIFont.systemFont(ofSize: !Settings.smallPlayer ? 19 : 15, weight: .semibold), .foregroundColor: UIColor.adaptableBlack]) + NSAttributedString(string: " ") + NSAttributedString(string: subtitle, attributes: [.font: UIFont.systemFont(ofSize: !Settings.smallPlayer ? 19 : 15, weight: .semibold), .foregroundColor: UIColor.adaptableBlack.withAlphaComponent(0.5)])
                    } else {
                        self.playerViewController.popupItem.attributedTitle = NSAttributedString(string: currentItem.title ?? "", attributes: [.font: UIFont.systemFont(ofSize: !Settings.smallPlayer ? 19 : 15, weight: .semibold)])
                    }
                }
                self.view.layoutIfNeeded()
            } completion: { _ in
                self.setPlayerControls()
            }
        })
        
        observables.append(UserDefaults.standard.observe(UInt32.self, key: "_accentColor") {
            _ = $0
            self.setPlayerControls()
            self.tabBar.tintColor = .getAccentColor(fromType: .common)
            self.playerViewController.artistLabel?.textColor = .getAccentColor(fromType: .common)
        })
        
        observables.append(UserDefaults.standard.observe(Bool.self, key: "_progressDown") {
            let isProgressDown = $0
            self.popupBar.progressViewStyle = isProgressDown ? .bottom : .top
        })
        
        setPlayerControls()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationItem.largeTitleDisplayMode = .always
        navigationController?.navigationBar.prefersLargeTitles = true
        
        setupViewControllers()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        setPlayerControls()
        view.layoutIfNeeded()
    }
    
    private func setPlayerControls() {
        playerViewController.popupItem.leadingBarButtonItems = []
        playerViewController.popupItem.trailingBarButtonItems = []

        if Settings.smallPlayer {
            playerViewController.popupItem.leadingBarButtonItems = [
                UIBarButtonItem(image: .init(named: AudioService.instance.player?.currentItem?.isPlaying ?? false ? "Pause Fill" : "Play Fill")?.resize(toWidth: Settings.smallPlayer ? 16 : 28)?.resize(toHeight: Settings.smallPlayer ? 16 : 28)?.tint(with: Settings.smallPlayer ? .getAccentColor(fromType: .common) : .secondBlack), style: .plain, target: self, action: #selector(playOrResume(_:))),
            ]
            switch AudioService.instance.player!.state {
            case .playing, .waitingForConnection, .buffering:
                playerViewController.popupItem.trailingBarButtonItems = [
                    UIBarButtonItem(image: .init(named: "forward.fill")?.tint(with: .getAccentColor(fromType: .common)), style: .plain, target: self, action: #selector(stopPlayer(_:)))
                    
                ]
            case .paused, .stopped, .failed(_):
                playerViewController.popupItem.trailingBarButtonItems = [
                    UIBarButtonItem(image: .init(named: "cancel_24 @ close")?.resize(toWidth: Settings.smallPlayer ? 20 : 28)?.resize(toHeight: Settings.smallPlayer ? 20 : 28)?.tint(with: .secondBlack.withAlphaComponent(0.6)), style: .plain, target: self, action: #selector(stopPlayer(_:)))
                ]
            }
        } else {
            playerViewController.popupItem.trailingBarButtonItems = []
            playerViewController.popupItem.leadingBarButtonItems = [
                UIBarButtonItem(image: .init(named: "backward.fill")?.resize(toWidth: Settings.smallPlayer ? 20 : 28)?.resize(toHeight: Settings.smallPlayer ? 20 : 28)?.tint(with: Settings.smallPlayer ? .getAccentColor(fromType: .common) : .secondBlack), style: .plain, target: self, action: #selector(previousTrack(_:))),
                UIBarButtonItem(image: .init(named: AudioService.instance.player?.currentItem?.isPlaying ?? false ? "Pause Fill" : "Play Fill")?.resize(toWidth: Settings.smallPlayer ? 16 : 28)?.resize(toHeight: Settings.smallPlayer ? 16 : 28)?.tint(with: Settings.smallPlayer ? .getAccentColor(fromType: .common) : .secondBlack), style: .plain, target: self, action: #selector(playOrResume(_:))),
                UIBarButtonItem(image: .init(named: "forward.fill")?.resize(toWidth: Settings.smallPlayer ? 20 : 28)?.resize(toHeight: Settings.smallPlayer ? 20 : 28)?.tint(with: Settings.smallPlayer ? .getAccentColor(fromType: .common) : .secondBlack), style: .plain, target: self, action: #selector(nextTrack(_:)))
            ]
        }
    }

    private func createNavigationController(for rootViewController: UIViewController, title: String?, image: UIImage?) -> UIViewController {
        let navController = rootViewController.withNavigationController()
        navController.tabBarItem.title = title
        navController.tabBarItem.image = image
        rootViewController.navigationItem.title = title
        rootViewController.navigationItem.largeTitleDisplayMode = .always
        navController.navigationBar.prefersLargeTitles = true
        return navController
    }
    
    private func setupViewControllers() {
        viewControllers = [
            createNavigationController(for: VKAudioController(), title: "Музыка", image: .init(named: "music_outline_28")),
            createNavigationController(for: PlaylistsViewController(), title: "Плейлисты", image: .init(named: "playlist_outline_28")),
            createNavigationController(for: SearchAudioViewController(), title: "Поиск", image: .init(named: "search_outline_28")),
            createNavigationController(for: SavedMusicViewController(), title: "Сохраненные", image: .init(named: "download_cloud_outline_28")),
            createNavigationController(for: ASSettingsViewController(), title: "Настройки", image: .init(named: "settings_outline_28"))
        ]
    }
    
    func showEventMessage(_ type: PrintType, message: String = "") {
        switch type {
        case .debug:
            SPAlert.present(title: "", message: message, preset: .done, haptic: .none)
        case .error:
            SPAlert.present(title: "Ошибка", message: message, preset: .error, haptic: .error)
        case .warning:
            SPAlert.present(title: "Внимание", message: message, preset: .custom((.init(named: "alert-triangle") ?? UIImage())), haptic: .warning)
        case .success:
            SPAlert.present(title: "Успешно", message: message, preset: .done, haptic: .success)
        }
    }
    
    @objc func playOrResume(_ recognizer: UITapGestureRecognizer) {
        DispatchQueue.main.async { [self] in
            guard let player = AudioService.instance.player else {
                return
            }
            
            switch player.state {
            case .buffering:
                log("item buffering", type: .debug)
            case .playing:
                player.pause()
            case .paused:
                player.resume()
            case .stopped:
                player.play(items: audioItems, startAtIndex: 0)
            case .waitingForConnection:
                log("player wait connection", type: .warning)
            case .failed(let error):
                log(error.localizedDescription, type: .error)
            }
        }
    }
    
    @objc func nextTrack(_ recognizer: UITapGestureRecognizer) {
        guard let player = AudioService.instance.player else {
            return
        }
        
        player.nextOrStop()
    }
    
    @objc func previousTrack(_ recognizer: UITapGestureRecognizer) {
        guard let player = AudioService.instance.player, player.hasPrevious else {
            return
        }
        
        player.previous()
    }
    
    @objc func stopPlayer(_ recognizer: UITapGestureRecognizer) {
        guard let player = AudioService.instance.player, player.hasPrevious else {
            return
        }
        
        switch player.state {
        case .playing:
            player.nextOrStop()
        case .buffering, .waitingForConnection, .paused:
            player.stop()
            dismissPopupBar(animated: true)
        case .stopped, .failed(_):
            break
        }
    }
}

extension VKTabController: AudioPlayerDelegate {
    func audioPlayer(_ audioPlayer: AudioPlayer, didChangeStateFrom from: AudioPlayerState, to state: AudioPlayerState) {
        DispatchQueue.main.async { [self] in
            switch state {
            case .playing, .paused:
                break
            case .buffering, .waitingForConnection:
                break
            case .stopped:
                break
            case .failed(let audioPlayerError):
                showEventMessage(.error, message: audioPlayerError.localizedDescription)
            }
        }
    }
    
    func audioPlayer(_ audioPlayer: AudioPlayer, shouldStartPlaying item: AudioPlayerItem) -> Bool {
        guard let url = URL(string: item.url) else {
            showEventMessage(.error, message: "Ссылка на аудио недоступна")
            return false
        }
        return UIApplication.shared.canOpenURL(url)
    }
    
    func audioPlayer(_ audioPlayer: AudioPlayer, willStartPlaying item: AudioPlayerItem) {
        DispatchQueue.main.async { [self] in
            item.isPlaying = true
            item.isPaused = false
            
            playerViewController.configure(withItem: item)
            playerViewController.popupItem.progress = 0
            playerViewController.item = item
            
            if let url = URL(string: item.albumThumb600) {
                KingfisherManager.shared.retrieveImage(with: url, options: nil) { receivedSize, totalSize in
                    print(receivedSize, totalSize)
                } completionHandler: { result in
                    switch result {
                    case .success(let value):
                        self.playerViewController.popupItem.image = value.image
                    case .failure(_):
                        self.playerViewController.popupItem.image = .init(named: "missing_song_artwork_generic_proxy")
                    }
                }
            } else {
                self.playerViewController.popupItem.image = .init(named: "missing_song_artwork_generic_proxy")
            }

            if let subtitle = item.subtitle, !subtitle.isEmpty {
                playerViewController.popupItem.attributedTitle = NSAttributedString(string: item.title ?? "", attributes: [.font: UIFont.systemFont(ofSize: !Settings.smallPlayer ? 19 : 15, weight: .semibold), .foregroundColor: UIColor.adaptableBlack]) + NSAttributedString(string: " ") + NSAttributedString(string: subtitle, attributes: [.font: UIFont.systemFont(ofSize: !Settings.smallPlayer ? 19 : 15, weight: .semibold), .foregroundColor: UIColor.adaptableBlack.withAlphaComponent(0.5)])
            } else {
                playerViewController.popupItem.attributedTitle = NSAttributedString(string: item.title ?? "", attributes: [.font: UIFont.systemFont(ofSize: !Settings.smallPlayer ? 19 : 15, weight: .semibold)])
            }
            
            playerViewController.popupItem.subtitle = item.artist
            
            if !Settings.smallPlayer {
                playerViewController.popupItem.leadingBarButtonItems?[1].image = .init(named: "Pause Fill")?.tint(with: Settings.smallPlayer ? .getAccentColor(fromType: .common) : .secondBlack)
            } else {
                playerViewController.popupItem.leadingBarButtonItems?[0].image = .init(named: "pause.fill")?.tint(with: Settings.smallPlayer ? .getAccentColor(fromType: .common) : .secondBlack)
                playerViewController.popupItem.trailingBarButtonItems?[0].image = .init(named: "forward.fill")?.tint(with: .getAccentColor(fromType: .common))
            }
            
            NotificationCenter.default.post(name: NSNotification.Name("WillResumePlaying"), object: audioPlayer, userInfo: ["item": item])
            
            if Settings.downloadAsPlaying {
                if Settings.downloadOnlyWifi && connectionType == .wifi || !Settings.downloadOnlyWifi {
                    do {
                        try item.downloadAudio()
                    } catch {
                        print(error)
                    }
                }
            }
        }
    }
    
    func audioPlayer(_ audioPlayer: AudioPlayer, willStopPlaying item: AudioPlayerItem) {
        DispatchQueue.main.async {
            item.isPlaying = false
            item.isPaused = false
            
            NotificationCenter.default.post(name: NSNotification.Name("WillResumePlaying"), object: audioPlayer, userInfo: ["item": item])
        }
    }
    
    func audioPlayer(_ audioPlayer: AudioPlayer, willPausePlaying item: AudioPlayerItem) {
        DispatchQueue.main.async { [self] in
            item.isPlaying = false
            item.isPaused = true
            
            if !Settings.smallPlayer {
                playerViewController.popupItem.leadingBarButtonItems?[1].image = .init(named: "Play Fill")?.tint(with: Settings.smallPlayer ? .getAccentColor(fromType: .common) : .secondBlack)
            } else {
                playerViewController.popupItem.leadingBarButtonItems?[0].image = .init(named: "play.fill")?.tint(with: Settings.smallPlayer ? .getAccentColor(fromType: .common) : .secondBlack)
                playerViewController.popupItem.trailingBarButtonItems?[0].image = .init(named: "cancel_24 @ close")?.resize(toWidth: Settings.smallPlayer ? 20 : 28)?.resize(toHeight: Settings.smallPlayer ? 20 : 28)?.tint(with: .secondBlack.withAlphaComponent(0.6))
            }
            
            NotificationCenter.default.post(name: NSNotification.Name("WillResumePlaying"), object: audioPlayer, userInfo: ["item": item])
        }
    }
    
    func audioPlayer(_ audioPlayer: AudioPlayer, willResumePlaying item: AudioPlayerItem) {
        DispatchQueue.main.async { [self] in
            item.isPlaying = true
            item.isPaused = false

            if !Settings.smallPlayer {
                playerViewController.popupItem.leadingBarButtonItems?[1].image = .init(named: "Pause Fill")?.tint(with: Settings.smallPlayer ? .getAccentColor(fromType: .common) : .secondBlack)
            } else {
                playerViewController.popupItem.leadingBarButtonItems?[0].image = .init(named: "pause.fill")?.tint(with: Settings.smallPlayer ? .getAccentColor(fromType: .common) : .secondBlack)
                playerViewController.popupItem.trailingBarButtonItems?[0].image = .init(named: "forward.fill")?.tint(with: .getAccentColor(fromType: .common))
            }
            
            NotificationCenter.default.post(name: NSNotification.Name("WillResumePlaying"), object: audioPlayer, userInfo: ["item": item])
        }
    }
    
    func audioPlayer(_ audioPlayer: AudioPlayer, didUpdateProgressionTo time: TimeInterval, percentageRead: Float) {
        playerViewController.popupItem.progress = percentageRead / 100
    }
}
