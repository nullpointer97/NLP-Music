//
//  ASAudioViewController.swift
//  vkmusic
//
//  Created by Ярослав Стрельников on 09.02.2022.
//  Copyright © 2022 NP-Team. All rights reserved.
//

import UIKit
import AsyncDisplayKit
import Alamofire
import CoreStore

class ASAudioViewController: ASBaseViewController<ASTableNode> {
    var dataSource: DiffableDataSource.TableNodeAdapter<AudioItem>?
    var audioItems: [AudioItem] = VKAudioDataStackService.audios.snapshot.compactMap { $0.object }
    var searchController: UISearchController?
    var playerViewController = PlayerViewController(item: nil)
    
    var refreshControl = UIRefreshControl()
    
    var tableNode: ASTableNode! {
        return node as? ASTableNode
    }
    
    override var bottomDockingViewForPopupBar: UIView? {
        return blurEffectView
    }
    
    override var defaultFrameForBottomDockingView: CGRect {
        var bottomViewFrame = blurEffectView.frame
        
        bottomViewFrame.origin = CGPoint(x: bottomViewFrame.origin.x, y: view.bounds.height)
        
        return bottomViewFrame
    }
    
    override func viewDidLoad() {
        setupTableNode()

        super.viewDidLoad()
        
        do {
            try getAudio()
        } catch {
            print(error)
        }
        
        navigationItem.largeTitleDisplayMode = .always
        
        title = "Nullpointer VK Music"
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: .init(named: "settings"), style: .done, target: self, action: #selector(logoutAccount))
        
        searchController = UISearchController(searchResultsController: nil)
        searchController?.searchBar.placeholder = "Искать в музыке"

        navigationItem.searchController = searchController
        
        AudioService.instance.player?.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(onAppResume(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onItemDownload(_:)), name: NSNotification.Name("AudioDownloaded"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didClearCache), name: NSNotification.Name("didCleanCache"), object: nil)
        
        playerViewController.popupItem.image = .init(named: "missing_song_artwork_generic_proxy")
        
        navigationController?.popupInteractionStyle = .drag
        navigationController?.popupBar.barStyle = UserDefaults.standard.bool(forKey: "_smallPlayer") ? .compact : .prominent
        navigationController?.popupBar.progressViewStyle = .top
        navigationController?.presentPopupBar(withContentViewController: playerViewController, animated: true)
        
        setPlayerControls()
        
        observables.append(UserDefaults.standard.observe(Bool.self, key: "_smallPlayer") {
            let isSmall = $0
            
            UIView.animate(withDuration: 0.3, delay: 0, options: .preferredFramesPerSecond60) {
                self.navigationController?.popupBar.barStyle = !isSmall ? .prominent : .compact
                self.setPlayerControls()
                
                self.view.layoutIfNeeded()
            }
        })
    }
    
    private func setPlayerControls() {
        playerViewController.popupItem.trailingBarButtonItems = [
            UIBarButtonItem(image: .init(named: AudioService.instance.player?.currentItem?.isPlaying ?? false ? "Pause Fill" : "Play Fill")?.tint(with: .secondBlack), style: .plain, target: self, action: #selector(playOrResume(_:))),
            UIBarButtonItem(image: .init(named: "Forward Fill")?.tint(with: .secondBlack), style: .plain, target: self, action: #selector(nextTrack(_:)))
        ]
        playerViewController.popupItem.leadingBarButtonItems = [
            UIBarButtonItem(image: .init(named: "Backward Fill")?.tint(with: .secondBlack), style: .plain, target: self, action: #selector(previousTrack(_:)))
        ]
    }
    
    private func setupTableNode() {
        view.addSubnode(node)
        tableNode.delegate = self
        tableNode.view.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(refreshAudio), for: .valueChanged)
        
        dataSource = AudioDataSource<AudioItem>(tableNode: tableNode, dataStack: VKAudioDataStackService.dataStack, cellProvider: { tableNode, indexPath, audioItem in
            let node = ASAudioNode(ASAudioItem(artworkUrl: audioItem.albumThumb135,
                                               title: audioItem.title ?? "unknown",
                                               artist: audioItem.artist ?? "unknown",
                                               isDownload: audioItem.isDownloaded,
                                               isPlaying: audioItem.isPlaying ?? false,
                                               isPaused: audioItem.isPaused ?? false))
            node.menuDelegate = self
            node.itemDelegate = self
            return node
        })
        dataSource?.apply(VKAudioDataStackService.audios.snapshot, animatingDifferences: false)

        VKAudioDataStackService.audios.addObserver(self) { [weak self] listPublisher in
            guard let self = self else { return }
            self.dataSource?.apply(listPublisher.snapshot, animatingDifferences: false)
            self.audioItems = VKAudioDataStackService.audios.snapshot.compactMap { $0.object }
        }
    }
    
    @objc private func refreshAudio() {
        do {
            try getAudio()
        } catch {
            print(error)
        }
    }
    
    private func getAudio() throws {
        var parametersAudio: Parameters = [
            "owner_id" : currentUserId
        ]
        
        try ApiV2.method("execute.getMusicPage", parameters: &parametersAudio, apiVersion: "5.90").done { result in
            try VKAudioDataStackService.dataStack.perform { transaction in
                let currentAudioIds = result["response"]["audios"]["items"].arrayValue
                    .sorted(by: { $0["date"].intValue > $1["date"].intValue })
                    .compactMap { $0["id"].intValue }
                
                let writedAudioIds = VKAudioDataStackService.audios.snapshot
                    .compactMap { $0.object }
                    .sorted(by: { $0.date ?? 0 > $1.date ?? 0 })
                    .compactMap { $0.id }

                try writedAudioIds.difference(from: currentAudioIds).forEach { id in
                    _ = try transaction.deleteAll(
                        From<AudioItem>(),
                        Tweak { request in
                            request.predicate = NSPredicate(format: "id == %@", argumentArray: [id])
                        }
                    )
                }
                
                result["response"]["audios"]["items"].arrayValue.forEach { (item) in
                    do {
                        _ = try transaction.importUniqueObject(Into<AudioItem>(), source: item)
                    } catch {
                        print(error.localizedDescription)
                    }
                }
                
                DispatchQueue.main.async {
                    self.refreshControl.endRefreshing()
                }
            }
        }.catch { error in
            print(error)
            DispatchQueue.main.async {
                self.refreshControl.endRefreshing()
            }
        }
    }
    
    @objc func reload() {
        tableNode.reloadData()
    }
    
    @objc func onAppResume(_ notification: Notification) {
        reload()
    }
    
    @objc func didClearCache() {
        reload()
    }
    
    @objc func playOrResume(_ recognizer: UITapGestureRecognizer) {
        guard let player = AudioService.instance.player, let item = player.currentItem else {
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
            player.play(item: item)
        case .waitingForConnection:
            log("player wait connection", type: .warning)
        case .failed(let error):
            log(error.localizedDescription, type: .error)
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
    
    @objc func onItemDownload(_ notification: Notification) {
        guard let item = notification.userInfo?["audioItem"] as? AudioItem else { return }
        if audioItems.contains(item), let index = audioItems.firstIndex(of: item) {
            updatePlayItem(byIndexPath: IndexPath(row: index, section: 0))
        }
    }
    
    @objc func logoutAccount() {
        navigationController?.pushViewController(ASSettingsViewController(), animated: true)
    }
}

extension ASAudioViewController: ASTableDelegate {
    func tableNode(_ tableNode: ASTableNode, constrainedSizeForRowAt indexPath: IndexPath) -> ASSizeRange {
        let size = CGSize(width: tableNode.view.contentSize.width, height: 56)
        return .init(min: size, max: size)
    }
    
    func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        tableNode.deselectRow(at: indexPath, animated: true)
    }
}

extension ASAudioViewController: AudioPlayerDelegate {
    func audioPlayer(_ audioPlayer: AudioPlayer, shouldStartPlaying item: AudioItem) -> Bool {
        guard let url = URL(string: item.url) else { return false }
        return UIApplication.shared.canOpenURL(url)
    }
    
    func audioPlayer(_ audioPlayer: AudioPlayer, willStartPlaying item: AudioItem) {
        guard let indexPath = getIndexPath(byItem: item) else { return }
        item.isPlaying = true
        item.isPaused = false
        updatePlayItem(byIndexPath: indexPath)
        playerViewController.progressView.progress = 0
        playerViewController.popupItem.title = item.title
        playerViewController.popupItem.subtitle = nil
        playerViewController.item = item
        
        playerViewController.titleLabel.text = item.title
        playerViewController.artistLabel.text = item.artist
        
        playerViewController.HQView.isHidden = !(item.isHQ ?? false)
        playerViewController.explicitView.isHidden = !(item.isExplicit ?? false)
        
        playerViewController.changePlayButton()
        
        DispatchQueue.main.async { [self] in
            if let url = URL(string: item.albumThumb300) {
                do {
                    playerViewController.popupItem.image = UIImage(data: try Data(contentsOf: url))
                } catch {
                    playerViewController.popupItem.image = .init(named: "missing_song_artwork_generic_proxy")
                }
            } else {
                playerViewController.popupItem.image = .init(named: "missing_song_artwork_generic_proxy")
            }
        }
        
        playerViewController.popupItem.trailingBarButtonItems?[0].image = .init(named: "Pause Fill")?.tint(with: .secondBlack)
        
        if Settings.downloadAsPlaying {
            do {
                try item.downloadAudio()
            } catch {
                print(error)
            }
        }
    }
    
    func audioPlayer(_ audioPlayer: AudioPlayer, willStopPlaying item: AudioItem) {
        guard let indexPath = getIndexPath(byItem: item) else { return }
        item.isPlaying = false
        item.isPaused = false
        updatePlayItem(byIndexPath: indexPath)
    }
    
    func audioPlayer(_ audioPlayer: AudioPlayer, willPausePlaying item: AudioItem) {
        guard let indexPath = getIndexPath(byItem: item) else { return }
        item.isPlaying = false
        item.isPaused = true
        
        playerViewController.titleLabel.text = item.title
        playerViewController.artistLabel.text = item.artist
        
        updatePlayItem(byIndexPath: indexPath)
        playerViewController.changePlayButton()
        
        playerViewController.popupItem.trailingBarButtonItems?[0].image = .init(named: "Play Fill")?.tint(with: .secondBlack)
    }
    
    func audioPlayer(_ audioPlayer: AudioPlayer, willResumePlaying item: AudioItem) {
        guard let indexPath = getIndexPath(byItem: item) else { return }
        item.isPlaying = true
        item.isPaused = false
        
        playerViewController.titleLabel.text = item.title
        playerViewController.artistLabel.text = item.artist
        
        updatePlayItem(byIndexPath: indexPath)
        playerViewController.changePlayButton()
        
        playerViewController.popupItem.trailingBarButtonItems?[0].image = .init(named: "Pause Fill")?.tint(with: .secondBlack)
    }
    
    func audioPlayer(_ audioPlayer: AudioPlayer, didUpdateProgressionTo time: TimeInterval, percentageRead: Float) {
        guard let duration = audioPlayer.currentItem?.duration else { return }

        playerViewController.popupItem.progress = percentageRead / 100
        playerViewController.progressView.progress = percentageRead / 100
        playerViewController.timeElapsedLabel.text = time.stringDuration
        playerViewController.timeElapsedLabel.sizeToFit()
        playerViewController.durationLabel.text = (time - Double(duration)).stringDuration.replacingOccurrences(of: ":-", with: ":")
        playerViewController.durationLabel.sizeToFit()
    }
    
    private func getIndexPath(byItem item: AudioItem) -> IndexPath? {
        guard let index = audioItems.firstIndex(of: item) else { return nil }
        return IndexPath(row: index, section: 0)
    }
    
    private func updatePlayItem(byIndexPath indexPath: IndexPath) {
        tableNode.reloadRows(at: [indexPath], with: .none)
    }
}

extension ASAudioViewController: AudioItemActionDelegate {
    func didSaveAudio(_ item: AudioItem) {
        ContextMenu.shared.dismiss()
        
        do {
            try item.downloadAudio()
        } catch {
            print(error)
        }
    }
}

extension ASAudioViewController: ASItemDelegate {
    func didTap(_ node: ASAudioNode) {
        guard let indexPath = tableNode.indexPath(for: node), let player = AudioService.instance.player else { return }
        let selectedItem = audioItems[indexPath.row]

        switch player.state {
        case .buffering:
            log("item buffering", type: .debug)
        case .playing:
            if player.currentItem == selectedItem {
                player.pause()
            } else {
                player.play(items: audioItems, startAtIndex: indexPath.row)
            }
        case .paused:
            if player.currentItem == selectedItem {
                player.resume()
            } else {
                player.play(items: audioItems, startAtIndex: indexPath.row)
            }
        case .stopped:
            player.play(items: audioItems, startAtIndex: indexPath.row)
        case .waitingForConnection:
            log("player wait connection", type: .warning)
        case .failed(let error):
            log(error.localizedDescription, type: .error)
        }
    }
}

extension ASAudioViewController: ASMenuDelegate {
    func didOpenMenu(_ node: ASAudioNode) {
        guard let indexPath = tableNode.indexPath(for: node) else { return }
        let menu = MenuViewController(from: audioItems[indexPath.row])
        menu.actionDelegate = self
        menu.actions = [
            [AudioItemAction(title: "Сохранить", action: { item in
                print("Save audio...")
            })]
        ]
        
        ContextMenu.shared.show(
            sourceViewController: self,
            viewController: menu,
            options: ContextMenu.Options(
                containerStyle: ContextMenu.ContainerStyle(
                    backgroundColor: .contextColor
                ),
                menuStyle: .default,
                hapticsStyle: .medium,
                position: .centerX
            ),
            sourceView: node.view,
            delegate: nil
        )
    }
}

struct ASAudioItem {
    var artworkUrl: String?
    var title: String
    var artist: String
    
    var isDownload: Bool
    var isPlaying: Bool
    var isPaused: Bool
}
