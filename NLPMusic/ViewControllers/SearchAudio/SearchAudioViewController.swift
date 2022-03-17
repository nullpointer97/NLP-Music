//
//  SearchAudioViewController.swift
//  vkmusic
//
//  Created by Ярослав Стрельников on 01.03.2022.
//  Copyright © 2022 NP-Team. All rights reserved.
//

import UIKit
import Alamofire

class SearchAudioViewController: VKBaseViewController {
    var tableView: UITableView!
    var footer: UITableViewFooter = UITableViewFooter(frame: .init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 40))
    var isPageNeed: Bool = true
    var searchController: UISearchController!
    var searchKeyword: String = ""
    
    var audioItems: [AudioPlayerItem] = []
    
    var vkTabBarController: VKTabController? {
        return tabBarController as? VKTabController
    }
    
    var isCurrentTabPlaying: Bool = false {
        didSet {
            vkTabBarController?.playerViewController.currentTabString = "Текущий список: Поиск"
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
        
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.delegate = self
        searchController.searchBar.setImage(UIImage(named: "search_outline_28")?.resize(toWidth: 18)?.resize(toHeight: 18)?.tint(with: .systemGray), for: .search, state: .normal)
        
        navigationItem.searchController = searchController
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupTable()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        reload()
        
        vkTabBarController?.audioItems = audioItems
        
        guard isCurrentTabPlaying else { return }
        vkTabBarController?.playerViewController.currentTabString = "Текущий список: Поиск"
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        searchController.searchBar.setImage(UIImage(named: "search")?.resize(toWidth: 18)?.resize(toHeight: 18)?.tint(with: .systemGray), for: .search, state: .normal)
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
                    tabBarController?.openPopup(animated: true)
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
                        tabBarController?.presentPopupBar(withContentViewController: playerViewController, animated: true, completion: nil)
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
        tableView?.add(to: view)
        tableView?.autoPinEdgesToSuperviewEdges()
        tableView?.delegate = self
        tableView?.register(.listCell(.audio), forCellReuseIdentifier: .listCell(.audio))
        tableView?.separatorStyle = .none
        tableView?.alwaysBounceVertical = true
        
        tableView.dataSource = self
        
        tableView.tableFooterView = footer

        footer.isLoading = false
        
        NotificationCenter.default.addObserver(self, selector: #selector(onItemEdited(_:)), name: NSNotification.Name("AudioDownloaded"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onItemEdited(_:)), name: NSNotification.Name("AudioRemoved"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didClearCache), name: NSNotification.Name("didCleanCache"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updatePlayingItem(_:)), name: NSNotification.Name("WillResumePlaying"), object: nil)
    }
    
    func searchAudio(byKeyword keyword: String, isPaginate: Bool = false) throws {
        var parametersAudio: Parameters = [
            "q": keyword,
            "user_id" : currentUserId,
            "count" : 50,
            "offset": isPaginate ? self.audioItems.count : 0
        ]
        
        try ApiV2.method("audio.search", parameters: &parametersAudio, apiVersion: "5.90").done { result in
            self.isPageNeed = result["response"]["count"].intValue > self.audioItems.count
            
            let items = result["response"]["items"].arrayValue
            
            if isPaginate {
                self.audioItems.append(contentsOf: items.compactMap { AudioPlayerItem(fromJSON: $0) }.uniqued())
            } else {
                self.audioItems.removeAll()
                self.audioItems.insert(contentsOf: items.compactMap { AudioPlayerItem(fromJSON: $0) }.uniqued(), at: 0)
            }
            
            self.vkTabBarController?.playerViewController.queueItems = self.audioItems
        }.ensure {
            DispatchQueue.main.async { [self] in
                footer.isLoading = false
                tableView.reloadData()
            }
        }.catch { error in
            DispatchQueue.main.async { [self] in
                footer.loadingText = "Произошла ошибка при загрузке"
            }
            print(error)
        }
    }
    
    func addAudio(audio: AudioPlayerItem) throws {
        var parametersAudio: Parameters = [
            "audio_id" : audio.id,
            "owner_id" : audio.ownerId
        ]
        
        try ApiV2.method("audio.add", parameters: &parametersAudio, apiVersion: "5.90").done { result in            
            DispatchQueue.main.async { [self] in
                let audioViewController = (vkTabBarController?.viewControllers?.first as? VKMNavigationController)?.viewControllers.first as? VKAudioController
                audioViewController?.audioItems.insert(audio, at: 0)
                audioViewController?.tableView.insertRows(at: [IndexPath(row: 0, section: 1)], with: .left)
            }
        }.catch { error in
            DispatchQueue.main.async { [self] in
                footer.loadingText = "Произошла ошибка при добавлении"
            }
        }
    }
    
    @objc func updatePlayingItem(_ notification: Notification) {
        guard let item = notification.userInfo?["item"] as? AudioPlayerItem else { return }
        guard let indexPath = getIndexPath(byItem: item) else { return }
        updatePlayItem(byIndexPath: indexPath)
    }
    
    @objc func reload() {
        tableView?.reloadData()
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
}

extension SearchAudioViewController: UISearchControllerDelegate {
    func willDismissSearchController(_ searchController: UISearchController) {
        searchController.searchBar.placeholder = searchKeyword
    }
}

extension SearchAudioViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text, searchText.count >= 1 else { return }
        searchKeyword = searchText
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(performSearch), object: nil)
        perform(#selector(performSearch), with: nil, afterDelay: 1)
    }
    
    @objc private func performSearch() {
        footer.isLoading = true
        audioItems.removeAll()
        do {
            try searchAudio(byKeyword: searchKeyword, isPaginate: false)
        } catch {
            print(error)
        }
    }
}

extension SearchAudioViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        60
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == audioItems.count - 20 && isPageNeed {
            do {
                try searchAudio(byKeyword: searchKeyword, isPaginate: true)
            } catch {
                print(error)
            }
        }
    }
}

extension SearchAudioViewController: AudioItemActionDelegate {
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
        } catch {
            print(error)
        }
    }
}

extension SearchAudioViewController: MenuDelegate {
    func didOpenMenu(_ cell: VKBaseViewCell<AudioPlayerItem>) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let item = audioItems[indexPath.row]
        let menu = MenuViewController(from: item)
        menu.actionDelegate = self
        menu.actions = [
            [AudioItemAction(actionDescription: "save", title: "Сохранить", action: { _ in
                menu.actionDelegate?.didSaveAudio(item)
            }), AudioItemAction(actionDescription: "append", title: "Добавить к себе", action: { [weak self] _ in
                do {
                    try self?.addAudio(audio: item)
                } catch {
                    self?.showEventMessage(.error, message: "Произошла ошибка при добавлении")
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

extension SearchAudioViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        footer.loadingText = audioItems.isEmpty ? "Введите ключевое слово для поиска" : "Конец списка"
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
