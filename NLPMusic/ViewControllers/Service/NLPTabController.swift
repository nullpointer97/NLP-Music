//
//  NLPTabController.swift
//  vkmusic
//
//  Created by Ярослав Стрельников on 23.02.2022.
//  Copyright © 2022 NP-Team. All rights reserved.
//

import UIKit
import SPAlert
import Kingfisher
import CoreStore
import MaterialComponents
import RNCryptor

class NLPTabController: UITabBarController {
    var observables: [Observable] = []
    var playerViewController = NLPPlayerV2ViewController()
    
    var audioItems: [AudioPlayerItem] = []
    
    let downloadManager = DownloadManager()
    let downloadService = AudioDownloadManager()
    lazy var session: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: "downloadAudioFromPlaying")
        config.timeoutIntervalForRequest = 20
        
        let session = URLSession(configuration: config, delegate: self, delegateQueue: .main)
        return session
    }()
    
    var viewControllersNames: [String] = [
        "Музыка", "Рекомендации", "Поиск", "Друзья", "Настройки"
    ]
    
    init() {
        super.init(nibName: nil, bundle: nil)
        AudioService.instance.player?.secondDelegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        downloadService.session = session
        
        tabBar.tintColor = .getAccentColor(fromType: .common)
        tabBar.barStyle = .default
        
        popupPresentationDelegate = self

        popupInteractionStyle = Settings.dismissType == 0 ? .snap : .drag

        switch Settings.playerStyle {
        case 1:
            popupBar.customBarViewController = nil
            popupBar.barStyle = .compact
        case 2:
            popupBar.customBarViewController = NLPMiniPlayerController()
        default:
            popupBar.customBarViewController = nil
            popupBar.barStyle = .prominent
        }
        presentPopupBar(withContentViewController: playerViewController, animated: true, completion: nil)

        popupBar.progressViewStyle = Settings.progressDown ? .bottom : .top
        popupBar.progressView.progressTintColor = .getAccentColor(fromType: .common)
        popupContentView.popupCloseButtonStyle = .chevron
        
        playerViewController.popupItem.image = .init(named: "missing_song_artwork_generic_proxy")
        playerViewController.vkTabBarController = self
        playerViewController.popupItem.attributedTitle = NSAttributedString(string: "Ожидает", attributes: [.font: UIFont.systemFont(ofSize: Settings.playerStyle == 0 ? 19 : 13, weight: .semibold), .foregroundColor: UIColor.label])
        playerViewController.popupItem.attributedSubtitle = NSAttributedString(string: "воспроизведения", attributes: [.font: UIFont.systemFont(ofSize: Settings.playerStyle == 0 ? 15 : 12, weight: .regular), .foregroundColor: UIColor.secondaryLabel])
        
        observables.append(UserDefaults.standard.observe(Int.self, key: "_playerStyle") {
            let isSmall = $0
            
            UIView.transition(with: self.view, duration: 0.2) {
                switch isSmall {
                case 1:
                    self.popupBar.customBarViewController = nil
                    self.popupBar.barStyle = .compact
                case 2:
                    self.popupBar.customBarViewController = NLPMiniPlayerController()
                default:
                    self.popupBar.customBarViewController = nil
                    self.popupBar.barStyle = .prominent
                }
                
                self.popupBar.layoutIfNeeded()
                if let currentItem = AudioService.instance.player?.currentItem {
                    if let subtitle = currentItem.subtitle, !subtitle.isEmpty {
                    self.playerViewController.popupItem.attributedTitle = NSAttributedString(string: currentItem.title ?? "", attributes: [.font: UIFont.systemFont(ofSize: Settings.playerStyle == 0 ? 19 : 13, weight: .semibold), .foregroundColor: UIColor.label]) + NSAttributedString(string: " ") + NSAttributedString(string: subtitle, attributes: [.font: UIFont.systemFont(ofSize: Settings.playerStyle == 0 ? 19 : 13, weight: .semibold), .foregroundColor: UIColor.secondaryLabel.withAlphaComponent(0.5)])
                    } else {
                        self.playerViewController.popupItem.attributedTitle = NSAttributedString(string: currentItem.title ?? "", attributes: [.font: UIFont.systemFont(ofSize: Settings.playerStyle == 0 ? 19 : 13, weight: .semibold)])
                    }
                    self.playerViewController.popupItem.attributedSubtitle = NSAttributedString(string: currentItem.artist ?? "", attributes: [.font: UIFont.systemFont(ofSize: Settings.playerStyle == 0 ? 15 : 12, weight: .regular), .foregroundColor: UIColor.secondaryLabel])
                } else {
                    self.playerViewController.popupItem.attributedTitle = NSAttributedString(string: "Ожидает", attributes: [.font: UIFont.systemFont(ofSize: Settings.playerStyle == 0 ? 19 : 13, weight: .semibold), .foregroundColor: UIColor.label])
                    self.playerViewController.popupItem.attributedSubtitle = NSAttributedString(string: "воспроизведения", attributes: [.font: UIFont.systemFont(ofSize: Settings.playerStyle == 0 ? 15 : 12, weight: .regular), .foregroundColor: UIColor.secondaryLabel])
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
        })
        
        observables.append(UserDefaults.standard.observe(Bool.self, key: "_progressDown") {
            let isProgressDown = $0
            self.popupBar.progressViewStyle = isProgressDown ? .bottom : .top
        })
        
        observables.append(UserDefaults.standard.observe(Int.self, key: "_dismissType") {
            let type = $0
            self.popupInteractionStyle = type == 0 ? .snap : .drag
        })
        
        observables.append(UserDefaults.standard.observe(Bool.self, key: "_namesInTabbar") {
            let isEnabled = $0
            
            for (index, item) in (self.tabBar.items ?? []).enumerated() {
                UIView.animate(withDuration: 0.2, delay: 0, options: [.transitionCrossDissolve, .allowUserInteraction, .beginFromCurrentState]) {
                    item.imageInsets = isEnabled ? .zero : UIEdgeInsets(top: 8, left: 0, bottom: -8, right: 0)
                    item.title = isEnabled ? self.viewControllersNames[index] : nil
                }
            }
        })
        
        setPlayerControls()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationItem.largeTitleDisplayMode = .never
        navigationController?.navigationBar.prefersLargeTitles = false
        
        setupViewControllers()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            setPlayerControls()
            view.layoutIfNeeded()
        }
    }
    
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        if item == tabBar.items?[2] && selectedIndex == 2 {
            let navigationViewController = viewControllers?[2] as! NLPMNavigationController
            let searchViewController = navigationViewController.viewControllers.first as! NLPSearchAudioViewController
            searchViewController.searchController.isActive = true
            searchViewController.searchController.searchBar.becomeFirstResponder()
        }
    }
    
    private func setPlayerControls() {
        let playbackToggleButton = UIBarButtonItem(image: nil, style: .plain, target: self, action: #selector(playOrResume(_:)))
        let previousButton = UIBarButtonItem(image: nil, style: .plain, target: self, action: #selector(previousTrack(_:)))
        let nextButton = UIBarButtonItem(image: nil, style: .plain, target: self, action: #selector(nextTrack(_:)))
        
        switch popupBar.barStyle {
        case .compact:
            playbackToggleButton.image = UIImage(named: AudioService.instance.player?.currentItem?.isPlaying ?? false ? "pause.fill" : "play.fill")?.resize(toWidth: 22)?.resize(toHeight: 22)?.tint(with: .getAccentColor(fromType: .common))
            previousButton.image = UIImage(named: "backward.fill")?.resize(toWidth: 22)?.resize(toHeight: 22)?.tint(with: .getAccentColor(fromType: .common))
            nextButton.image = UIImage(named: "forward.fill")?.resize(toWidth: 22)?.resize(toHeight: 22)?.tint(with: .getAccentColor(fromType: .common))
        case .prominent:
            playbackToggleButton.image = UIImage(named: AudioService.instance.player?.currentItem?.isPlaying ?? false ? "Pause Fill" : "Play Fill")?.tint(with: .label)
            previousButton.image = UIImage(named: "Backward Fill")?.tint(with: .label)
            nextButton.image = UIImage(named: "Forward Fill")?.tint(with: .label)
        default:
            break
        }
        playerViewController.popupItem.leadingBarButtonItems = []
        playerViewController.popupItem.trailingBarButtonItems = []

        if Settings.playerStyle != 0 {
            playerViewController.popupItem.leadingBarButtonItems = [playbackToggleButton]
            playerViewController.popupItem.trailingBarButtonItems = [nextButton]
        } else {
            playerViewController.popupItem.trailingBarButtonItems = []
            playerViewController.popupItem.leadingBarButtonItems = [previousButton, playbackToggleButton, nextButton]
        }
    }
    
    internal func togglePlaybackButton() {
        switch popupBar.barStyle {
        case .compact:
            playerViewController.popupItem.leadingBarButtonItems?.first?.image = UIImage(named: AudioService.instance.player?.currentItem?.isPlaying ?? false ? "pause.fill" : "play.fill")?.resize(toWidth: 22)?.resize(toHeight: 22)
        case .prominent:
            playerViewController.popupItem.leadingBarButtonItems?[1].image = UIImage(named: AudioService.instance.player?.currentItem?.isPlaying ?? false ? "Pause Fill" : "Play Fill")?.tint(with: .label)
        default:
            break
        }
    }

    private func createNavigationController(for rootViewController: UIViewController, title: String?, navigationControllerTitle: String?, image: UIImage?, isASDK: Bool = false) -> UIViewController {
        let navigationController = NLPMNavigationController(navigationBarClass: nil, toolbarClass: nil)
        navigationController.viewControllers = [rootViewController]
        let navController = navigationController
        navController.tabBarItem.title = title
        navController.tabBarItem.image = image
        rootViewController.navigationItem.title = navigationControllerTitle
        return navController
    }
    
    private func setupViewControllers() {
        let names = Settings.namesInTabbar ? viewControllersNames : ["", "", "", "", ""]
        viewControllers = [
            createNavigationController(for: NLPAudioV2Wireframe().viewController, title: names[0], navigationControllerTitle: viewControllersNames[0], image: .init(named: "music_outline_28")),
            createNavigationController(for: NLPRecommendationsWireframe().viewController, title: names[1], navigationControllerTitle: viewControllersNames[1], image: .init(named: "fire_outline_28")),
            createNavigationController(for: NLPSearchAudioWireframe().viewController, title: names[2], navigationControllerTitle: viewControllersNames[2], image: .init(named: "search_outline_28")),
            createNavigationController(for: NLPFriendsViewController(), title: names[3], navigationControllerTitle: viewControllersNames[3], image: .init(named: "users_outline_28")),
            createNavigationController(for: NLPSettingsController(), title: names[4], navigationControllerTitle: viewControllersNames[4], image: .init(named: "settings_outline_28"))
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

extension NLPTabController: AudioPlayerDelegate {
    func audioPlayer(_ audioPlayer: AudioPlayer, didChangeStateFrom from: AudioPlayerState, to state: AudioPlayerState) {
        DispatchQueue.main.async { [self] in
            switch state {
            case .playing, .paused:
                togglePlaybackButton()
            case .buffering, .waitingForConnection:
                break
            case .stopped:
                break
            case .failed(let audioPlayerError):
                showEventMessage(.error, message: audioPlayerError.description)
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
    
    func audioPlayer(_ audioPlayer: AudioPlayer, didChangeModeFrom from: AudioPlayerMode, to mode: AudioPlayerMode) {
    }
    
    func audioPlayer(_ audioPlayer: AudioPlayer, willStartPlaying item: AudioPlayerItem) {
        postFromStartAudio(audioPlayer, item)
        DispatchQueue.main.async { [self] in
            playerViewController.popupItem.progress = 0
            
            if let url = URL(string: item.albumThumb600) {
                KingfisherManager.shared.retrieveImage(with: url, options: nil) { receivedSize, totalSize in
                    print(receivedSize, totalSize)
                } completionHandler: { result in
                    switch result {
                    case .success(let value):
                        self.playerViewController.popupItem.image = value.image
                    case .failure(_):
                        self.playerViewController.popupItem.image = .init(named: "playlist_outline_56")
                    }
                }
            } else {
                playerViewController.popupItem.image = .init(named: "playlist_outline_56")
            }

            if let subtitle = item.subtitle, !subtitle.isEmpty {
                playerViewController.popupItem.attributedTitle = NSAttributedString(string: item.title ?? "", attributes: [.font: UIFont.systemFont(ofSize: Settings.playerStyle == 0 ? 19 : 13, weight: .semibold), .foregroundColor: UIColor.label]) + NSAttributedString(string: " ") + NSAttributedString(string: subtitle, attributes: [.font: UIFont.systemFont(ofSize: Settings.playerStyle == 0 ? 19 : 13, weight: .semibold), .foregroundColor: UIColor.secondaryLabel])
            } else {
                playerViewController.popupItem.attributedTitle = NSAttributedString(string: item.title ?? "", attributes: [.font: UIFont.systemFont(ofSize: Settings.playerStyle == 0 ? 19 : 13, weight: .semibold), .foregroundColor: UIColor.label])
            }
            
            playerViewController.popupItem.attributedSubtitle = NSAttributedString(string: item.artist ?? "", attributes: [.font: UIFont.systemFont(ofSize: Settings.playerStyle == 0 ? 15 : 12, weight: .regular), .foregroundColor: UIColor.secondaryLabel])
            
            if Settings.downloadAsPlaying && !item.isDownloaded {
                if Settings.downloadOnlyWifi && connectionType == .wifi || !Settings.downloadOnlyWifi {
                    do {
                        try downloadService.download(item: item)
                    } catch {
                        print(error)
                    }
                }
            }
        }
    }
    
    func audioPlayer(_ audioPlayer: AudioPlayer, willStopPlaying item: AudioPlayerItem) {
        postFromStopAudio(audioPlayer, item)
    }
    
    func audioPlayer(_ audioPlayer: AudioPlayer, willPausePlaying item: AudioPlayerItem) {
        postFromPauseAudio(audioPlayer, item)
    }
    
    func audioPlayer(_ audioPlayer: AudioPlayer, willResumePlaying item: AudioPlayerItem) {
        postFromResumeAudio(audioPlayer, item)
    }
    
    func audioPlayer(_ audioPlayer: AudioPlayer, didUpdateProgressionTo time: TimeInterval, percentageRead: Float) {
        playerViewController.popupItem.progress = percentageRead / 100
    }
}

extension NLPTabController: LNPopupPresentationDelegate {
    func popupPresentationController(_ popupPresentationController: UIViewController, willOpenPopupWithContentController popupContentController: UIViewController, animated: Bool) {
        view.endEditing(true)
        if let item = AudioService.instance.player?.currentItem {
            playerViewController.configurePlayer(from: item)
        }
    }
    
    func popupPresentationController(_ popupPresentationController: UIViewController, didOpenPopupWithContentController popupContentController: UIViewController, animated: Bool) {
//        if let item = AudioService.instance.player?.currentItem {
//            playerViewController.configurePlayer(from: item)
//        }
    }
    
    func popupPresentationControllerWillOpenPopup(_ popupPresentationController: UIViewController, animated: Bool) {
        view.endEditing(true)
    }
    
    func popupPresentationControllerDidDismissPopupBar(_ popupPresentationController: UIViewController, animated: Bool) {
//        playerViewController.isListOpened = false
        if let item = playerViewController.item {
            playerViewController.configurePlayer(from: item)
        }
    }
    
    func popupPresentationController(_ popupPresentationController: UIViewController, didClosePopupWithContentController popupContentController: UIViewController, animated: Bool) {
//        playerViewController.isListOpened = false
    }
}

extension NLPTabController: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let documentsDirectoryURL: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("music_cache")

        guard let sourceURL = downloadTask.originalRequest?.url else {
            return
        }
        
        guard let download = downloadService.activeDownloads[sourceURL] else { return }
        downloadService.activeDownloads[sourceURL] = nil
        
        guard let url = URL(string: download.track.url) else { return }
        var destinationUrl = documentsDirectoryURL.appendingPathComponent("\(download.track.songName ?? "unknown").\(url.pathExtension)")

        do {
            try FileManager.default.moveItem(at: location, to: destinationUrl)

            /*
             let data = try Data(contentsOf: destinationUrl, options: [])
             let encryptFile = RNCryptor.encrypt(data: data, withPassword: "nlp_music_crypt")
             try encryptFile.write(to: destinationUrl, options: [.fileProtectionMask])
            */
            
            try AudioDataStackService.dataStack.perform { transaction in
                do {
                    _ = try transaction.importUniqueObject(Into<AudioItem>(), source: download.track)
                } catch {
                    print(error.localizedDescription)
                }
            }
            postFromDownloadAudio(download.track)
        } catch {
            print(error)
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard
            let url = downloadTask.originalRequest?.url,
            let download = downloadService.activeDownloads[url]  else {
            return
        }

        download.progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)

        print(download.progress)
    }
}

extension NLPTabController {
    func postFromStartAudio(_ player: AudioPlayer, _ item: AudioPlayerItem) {
        NotificationCenter.default.post(name: NSNotification.Name("didStartPlaying"), object: player, userInfo: ["item": item])
    }
    
    func postFromPauseAudio(_ player: AudioPlayer, _ item: AudioPlayerItem) {
        NotificationCenter.default.post(name: NSNotification.Name("didPausePlaying"), object: player, userInfo: ["item": item])
    }
    
    func postFromStopAudio(_ player: AudioPlayer, _ item: AudioPlayerItem) {
        NotificationCenter.default.post(name: NSNotification.Name("didStopPlaying"), object: player, userInfo: ["item": item])
    }
    
    func postFromResumeAudio(_ player: AudioPlayer, _ item: AudioPlayerItem) {
        NotificationCenter.default.post(name: NSNotification.Name("didResumePlaying"), object: player, userInfo: ["item": item])
    }
    
    func postFromDownloadAudio(_ item: AudioPlayerItem) {
        NotificationCenter.default.post(name: NSNotification.Name("didDownloadAudio"), object: nil, userInfo: ["item": item])
    }
}

extension String {
    static func createArray(withItems count: Int) -> Array<String> {
        var emptyArray = Array<String>()
        for _ in 0...count {
            emptyArray.append("")
        }
        return emptyArray
    }
}
