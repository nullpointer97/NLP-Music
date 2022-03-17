//
//  VKAudioController.swift
//  vkmusic
//
//  Created by Ярослав Стрельников on 02.02.2022.
//  Copyright © 2022 NP-Team. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import CoreStore
import ObjectMapper
import AsyncDisplayKit

class VKAudioController: VKBaseViewController {
    var tableView: UITableView!
    let deviceName = UIDevice.current.modelName
    var footer: UITableViewFooter = UITableViewFooter(frame: .init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 40))
    
    var isPageNeed: Bool = true
    lazy var refreshControl = UIRefreshControl()
    
    var audioItems: [AudioPlayerItem] = []
    
    var vkTabBarController: VKTabController? {
        return tabBarController as? VKTabController
    }
    
    var isCurrentTabPlaying: Bool = false {
        didSet {
            vkTabBarController?.playerViewController.currentTabString = "Текущий список: Музыка"
            vkTabBarController?.viewControllers?.filter { $0 != self }.forEach { controller in
                if let controller = controller as? SearchAudioViewController {
                    controller.isCurrentTabPlaying = false
                }
                if let controller = controller as? VKAudioController {
                    controller.isCurrentTabPlaying = false
                }
            }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupTable()
        
        do {
            try getAudio()
        } catch {
            print(error)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(onItemEdited(_:)), name: NSNotification.Name("AudioDownloaded"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onItemEdited(_:)), name: NSNotification.Name("AudioRemoved"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didClearCache), name: NSNotification.Name("didCleanCache"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updatePlayingItem(_:)), name: NSNotification.Name("WillResumePlaying"), object: nil)
        
        observables.append(UserDefaults.standard.observe(UInt32.self, key: "_accentColor") {
            _ = $0
            let cell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? VKPairButtonViewCell
            cell?.playButton.setTitleColor(.getAccentColor(fromType: .common), for: .normal)
            cell?.shuffleButton.setTitleColor(.getAccentColor(fromType: .common), for: .normal)
            
            cell?.playButton.setImage(.init(named: "play.fill")?.resize(toWidth: 20)?.resize(toHeight: 20)?.tint(with: .getAccentColor(fromType: .common)), for: .normal)
            cell?.shuffleButton.setImage(.init(named: "shuffle_24")?.resize(toWidth: 20)?.resize(toHeight: 20)?.tint(with: .getAccentColor(fromType: .common)), for: .normal)
            
            self.reload()
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        reload()
        
        vkTabBarController?.audioItems = audioItems
        
        guard isCurrentTabPlaying else { return }
        vkTabBarController?.playerViewController.currentTabString = "Текущий список: Музыка"
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        reload()
    }
    
    override func getIndexPath(byItem item: AudioPlayerItem) -> IndexPath? {
        guard let index = audioItems.firstIndex(of: item) else { return nil }
        return IndexPath(row: index, section: 1)
    }
    
    override func updatePlayItem(byIndexPath indexPath: IndexPath) {
        DispatchQueue.main.async { [self] in
            tableView.beginUpdates()
            tableView.reloadRows(at: [indexPath], with: .none)
            tableView.endUpdates()
        }
    }
    
    override func didTap<T>(_ cell: VKBaseViewCell<T>) {
        DispatchQueue.main.async { [self] in
            guard let indexPath = tableView.indexPath(for: cell), let player = AudioService.instance.player else { return }
            let selectedItem = audioItems[indexPath.row]
            
            switch player.state {
            case .buffering:
                log("item buffering", type: .debug)
            case .playing:
                if player.currentItem == selectedItem {
                    vkTabBarController?.openPopup(animated: true)
                } else {
                    isCurrentTabPlaying = true
                    player.play(items: audioItems, startAtIndex: indexPath.row)
                    vkTabBarController?.playerViewController.queueItems = audioItems
                }
            case .paused:
                if player.currentItem == selectedItem {
                    player.resume()
                } else {
                    isCurrentTabPlaying = true
                    player.play(items: audioItems, startAtIndex: indexPath.row)
                    vkTabBarController?.playerViewController.queueItems = audioItems
                }
            case .stopped:
                DispatchQueue.main.async { [self] in
                    if let playerViewController = vkTabBarController?.playerViewController {
                        vkTabBarController?.presentPopupBar(withContentViewController: playerViewController, animated: true, completion: nil)
                    }
                    isCurrentTabPlaying = true
                    player.play(items: audioItems, startAtIndex: indexPath.row)
                    vkTabBarController?.playerViewController.queueItems = audioItems
                }
            case .waitingForConnection:
                log("player wait connection", type: .warning)
            case .failed(let error):
                log(error.localizedDescription, type: .error)
            }
        }
    }
    
    func setupTable() {
        tableView = UITableView(frame: view.frame, style: .plain)
        tableView.add(to: view)
        tableView.autoPinEdgesToSuperviewEdges()
        tableView.register(.listCell(.audio), forCellReuseIdentifier: .listCell(.audio))
        tableView.register(.listCell(.pairButton), forCellReuseIdentifier: .listCell(.pairButton))

        tableView.tableFooterView = footer
        footer.isLoading = true
        
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(refreshAudio), for: .valueChanged)

        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.separatorStyle = .none
        tableView.alwaysBounceVertical = true
    }
    
    @objc func reload() {
        tableView.reloadData()
    }
    
    @objc func didClearCache() {
        reload()
    }
    
    @objc func onItemEdited(_ notification: Notification) {
        guard let item = notification.userInfo?["audioItem"] as? AudioPlayerItem else { return }
        if audioItems.contains(item), let index = audioItems.firstIndex(of: item) {
            updatePlayItem(byIndexPath: IndexPath(row: index, section: 0))
        }
    }
    
    @objc func updatePlayingItem(_ notification: Notification) {
        guard let item = notification.userInfo?["item"] as? AudioPlayerItem else { return }
        guard let indexPath = getIndexPath(byItem: item) else { return }
        updatePlayItem(byIndexPath: indexPath)
    }
    
    func getAudio(isPaginate: Bool = false) throws {
        var parametersAudio: Parameters = [
            "owner_id" : currentUserId,
        ]
        
        try ApiV2.method("execute.getPlaylist", parameters: &parametersAudio, apiVersion: "5.90").done { result in
            let items = result["response"]["audios"].arrayValue
            
            self.audioItems.removeAll()
            self.audioItems.append(contentsOf: items.compactMap { AudioPlayerItem(fromJSON: $0) }.uniqued())
        }.ensure {
            DispatchQueue.main.async { [self] in
                footer.isLoading = false
                refreshControl.endRefreshing()
                tableView.reloadData()
            }
        }.catch { error in
            DispatchQueue.main.async { [self] in
                footer.loadingText = "Произошла ошибка при загрузке"
            }
            print(error)
        }
    }
    
    func removeAudio(audio: AudioPlayerItem) throws {
        var parametersAudio: Parameters = [
            "audio_id" : audio.id,
            "owner_id" : audio.ownerId
        ]
        
        try ApiV2.method("audio.delete", parameters: &parametersAudio, apiVersion: "5.90").done { result in
            guard result["response"].intValue == 1 else { return }
            guard let indexPath = self.getIndexPath(byItem: audio) else { return }
            
            DispatchQueue.main.async { [self] in
                audioItems.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .left)
            }
        }.catch { error in
            DispatchQueue.main.async { [self] in
                footer.loadingText = "Произошла ошибка при удалении"
            }
        }
    }
    
    @objc private func refreshAudio() {
        do {
            try getAudio()
        } catch {
            print(error)
        }
    }
}

extension VKAudioController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        footer.loadingText = audioItems.isEmpty ? "У Вас нет аудиозаписей" : "Аудиозаписи загружены"
        return section == 0 ? 1 : audioItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: .listCell(.pairButton), for: indexPath) as? VKPairButtonViewCell else { return UITableViewCell() }
            cell.delegate = self
            return cell
        } else {
            let audio = audioItems[indexPath.row]
            guard let cell = tableView.dequeueReusableCell(withIdentifier: .listCell(.audio), for: indexPath) as? VKAudioViewCell else { return UITableViewCell() }
            cell.configure(with: audio)
            
            cell.delegate = self
            cell.menuDelegate = self
            
            return cell
        }
    }
}

extension VKAudioController: PairButtonDelegate {
    func didPlayAll(_ cell: VKPairButtonViewCell) {
        guard let player = AudioService.instance.player, audioItems.count > 0 else { return }
        
        if player.currentItem != nil || player.currentItem?.isPaused ?? false || player.currentItem?.isPlaying ?? false {
            AudioService.instance.player?.stop()
        }
        
        player.mode = .normal
        playing(player)
    }
    
    func didShuffleAll(_ cell: VKPairButtonViewCell) {
        guard let player = AudioService.instance.player, audioItems.count > 0 else { return }
        
        if player.currentItem != nil || player.currentItem?.isPaused ?? false || player.currentItem?.isPlaying ?? false {
            AudioService.instance.player?.stop()
        }

        player.mode = .shuffle
        playing(player, true)
    }
    
    private func playing(_ player: AudioPlayer, _ isShuffle: Bool = false) {
        if let playerViewController = vkTabBarController?.playerViewController {
            vkTabBarController?.presentPopupBar(withContentViewController: playerViewController, animated: true, completion: nil)
        }
        isCurrentTabPlaying = true
        vkTabBarController?.playerViewController.queueItems = audioItems
        player.play(items: audioItems, startAtIndex: isShuffle ? Int.random(in: 0...audioItems.count - 1) : 0)
    }
}

extension VKAudioController: AudioItemActionDelegate {
    func didSaveAudio(_ item: AudioPlayerItem) {
        ContextMenu.shared.dismiss()
        
        do {
            try item.downloadAudio()
        } catch {
            showEventMessage(.error, message: "\(error)")
        }
    }
    
    func didRemoveAudio(_ item: AudioPlayerItem) {
        ContextMenu.shared.dismiss()
        
        do {
            try item.removeAudio()
        } catch {
            print(error)
        }
    }
}

extension VKAudioController: MenuDelegate {
    func didOpenMenu(_ cell: VKBaseViewCell<AudioPlayerItem>) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let item = audioItems[indexPath.row]
        let menu = MenuViewController(from: item)
        menu.actionDelegate = self
        menu.actions = [
            [AudioItemAction(actionDescription: "save", title: "Сохранить", action: { _ in
                menu.actionDelegate?.didSaveAudio(item)
            }), AudioItemAction(actionDescription: "remove", title: "Удалить", action: { [weak self] _ in
                do {
                    try self?.removeAudio(audio: item)
                } catch {
                    self?.showEventMessage(.error, message: "Произошла ошибка при удалении")
                }
                ContextMenu.shared.dismiss()
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
            sourceView: cell.morePlaceholderButton,
            delegate: nil
        )
    }
}

extension VKAudioController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        indexPath.section == 0 ? 48 : 60
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
//        if indexPath.row == audioItems.count - 20 && isPageNeed {
//            do {
//                try getAudio(isPaginate: true)
//            } catch {
//                print(error)
//            }
//        }
    }
}

extension Sequence where Element: Hashable {
    func duplicates() -> [Element] {
        var set = Set<Element>()
        return filter { !set.insert($0).inserted }
    }
    
    func uniqued() -> [Element] {
        var set = Set<Element>()
        return filter { set.insert($0).inserted }
    }
}

extension Array where Element: Hashable {
    func difference(from other: [Element]) -> [Element] {
        let thisSet = Set(self)
        let otherSet = Set(other)
        return Array(thisSet.symmetricDifference(otherSet))
    }
}

extension Array {
    func element(toIndex index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}

extension UINib {
    static func listCell(_ cell: ListViewCell) -> UINib? {
        return UINib(nibName: cell.rawValue, bundle: nil)
    }
}

extension String {
    static func listCell(_ cell: ListViewCell) -> String {
        return cell.rawValue
    }
}
