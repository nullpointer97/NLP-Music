//
//  SavedMusicViewController.swift
//  vkmusic
//
//  Created by Ярослав Стрельников on 01.03.2022.
//  Copyright © 2022 NP-Team. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import CoreStore

class SavedMusicViewController: VKBaseViewController {
    var tableView: UITableView!
    var footer: UITableViewFooter = UITableViewFooter(frame: .init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 40))

    var audioItems: [AudioPlayerItem] = VKAudioDataStackService.getAudios().snapshot.compactMap { $0.object }.compactMap { AudioPlayerItem(from: $0) } {
        didSet {
            DispatchQueue.main.async {
                self.tableView?.reloadData()
            }
        }
    }
    
    var vkTabBarController: VKTabController? {
        return tabBarController as? VKTabController
    }
    
    var isCurrentTabPlaying: Bool = false {
        didSet {
            vkTabBarController?.playerViewController.currentTabString = "Текущий список: Сохраненные"
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
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTable()
        
        NotificationCenter.default.addObserver(self, selector: #selector(onItemEdited(_:)), name: NSNotification.Name("AudioDownloaded"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onItemEdited(_:)), name: NSNotification.Name("AudioRemoved"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didClearCache), name: NSNotification.Name("didCleanCache"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updatePlayingItem(_:)), name: NSNotification.Name("WillResumePlaying"), object: nil)
        
        VKAudioDataStackService.getAudios().addObserver(self) { [weak self] listPublisher in
            guard let self = self else { return }
            self.audioItems = listPublisher.snapshot.compactMap { $0.object }.compactMap { AudioPlayerItem(from: $0) }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        audioItems = VKAudioDataStackService.getAudios().snapshot.compactMap { $0.object }.compactMap { AudioPlayerItem(from: $0) }
        tableView?.reloadData()
        vkTabBarController?.audioItems = audioItems
        
        guard isCurrentTabPlaying else { return }
        vkTabBarController?.playerViewController.currentTabString = "Текущий список: Сохраненные"
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        tableView?.reloadData()
        
        view.layoutIfNeeded()
    }
    
    override func getIndexPath(byItem item: AudioPlayerItem) -> IndexPath? {
        guard let index = audioItems.firstIndex(of: item) else { return nil }
        return IndexPath(row: index, section: 0)
    }
    
    override func updatePlayItem(byIndexPath indexPath: IndexPath) {
        DispatchQueue.main.async { [self] in
            tableView?.beginUpdates()
            tableView?.reloadRows(at: [indexPath], with: .none)
            tableView?.endUpdates()
        }
    }
    
    override func didTap<T>(_ cell: VKBaseViewCell<T>) {
        DispatchQueue.main.async { [self] in
            guard let indexPath = tableView?.indexPath(for: cell), let player = AudioService.instance.player else { return }
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
        tableView = UITableView(frame: .zero, style: .plain)
        tableView.add(to: view)
        tableView.autoPinEdgesToSuperviewEdges()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(.listCell(.audio), forCellReuseIdentifier: .listCell(.audio))
        tableView.tableFooterView = footer
        
        tableView.separatorStyle = .none
        tableView.alwaysBounceVertical = true
    }
    
    @objc func onItemEdited(_ notification: Notification) {
    }
    
    @objc func didClearCache() {
        audioItems = VKAudioDataStackService.getAudios().snapshot.compactMap { $0.object }.compactMap { AudioPlayerItem(from: $0) }
        tableView.reloadData()
    }
    
    @objc func updatePlayingItem(_ notification: Notification) {
        guard let item = notification.userInfo?["item"] as? AudioPlayerItem else { return }
        guard let indexPath = getIndexPath(byItem: item) else { return }
        updatePlayItem(byIndexPath: indexPath)
    }
}

extension SavedMusicViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        footer.loadingText = audioItems.isEmpty ? "У Вас нет аудиозаписей" : ""
        return audioItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let audio = audioItems[indexPath.row]
        guard let cell = tableView.dequeueReusableCell(withIdentifier: .listCell(.audio), for: indexPath) as? VKAudioViewCell else { return UITableViewCell() }
        cell.configure(with: audio)
        
        cell.delegate = self
        cell.menuDelegate = self
        
        return cell
    }
}

extension SavedMusicViewController: AudioItemActionDelegate {
    func didSaveAudio(_ item: AudioPlayerItem) {
        ContextMenu.shared.dismiss()
        
        do {
            try item.downloadAudio()
        } catch {
            print(error)
        }
    }
    
    func didRemoveAudio(_ item: AudioPlayerItem) {
        ContextMenu.shared.dismiss()
        
        do {
            try item.removeAudio()
            guard let indexPath = getIndexPath(byItem: item) else { return }
            
            DispatchQueue.main.async { [self] in
                audioItems.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .left)
            }
        } catch {
            print(error)
        }
    }
}

extension SavedMusicViewController: MenuDelegate {
    func didOpenMenu(_ cell: VKBaseViewCell<AudioPlayerItem>) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let item = audioItems[indexPath.row]
        let menu = MenuViewController(from: item)
        menu.actionDelegate = self
        menu.actions = [
            [AudioItemAction(actionDescription: "remove", title: "Удалить", action: { _ in
                menu.actionDelegate?.didRemoveAudio(item)
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

extension SavedMusicViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        60
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
