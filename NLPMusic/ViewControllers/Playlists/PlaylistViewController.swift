//
//  PlaylistViewController.swift
//  vkmusic
//
//  Created by Ярослав Стрельников on 04.03.2022.
//  Copyright © 2022 NP-Team. All rights reserved.
//

import UIKit
import Kingfisher
import Alamofire

class PlaylistViewController: VKBaseViewController {
    let playlist: Playlist
    
    var tableView: UITableView!
    var header: UIView = UIView(frame: .init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: (UIScreen.main.bounds.width / 2) + 56))
    var footer: UITableViewFooter = UITableViewFooter(frame: .init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 40))

    var audioItems: [AudioPlayerItem] = []
    var isPageNeed: Bool = true
    lazy var refreshControl = UIRefreshControl()

    var vkTabBarController: VKTabController? {
        return tabBarController as? VKTabController
    }
    
    var isCurrentTabPlaying: Bool = false {
        didSet {
            vkTabBarController?.playerViewController.currentTabString = "Текущий список: \(playlist.title ?? "?")"
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
    
    init(_ playlist: Playlist) {
        self.playlist = playlist
        super.init(nibName: nil, bundle: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTable()
        
        do {
            try getPlaylists()
        } catch {
            print(error)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(updatePlayingItem(_:)), name: NSNotification.Name("WillResumePlaying"), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationItem.largeTitleDisplayMode = .never
        tableView.reloadData()
    }
    
    override func getIndexPath(byItem item: AudioPlayerItem) -> IndexPath? {
        guard let index = audioItems.firstIndex(of: item) else { return nil }
        return IndexPath(row: index, section: 0)
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
        
        if #available(iOS 15.0, *) {
            tableView.autoPinEdgesToSuperviewEdges(with: .top(-64))
        } else {
            tableView.autoPinEdgesToSuperviewEdges()
        }
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(.listCell(.miniAudio), forCellReuseIdentifier: .listCell(.miniAudio))
        tableView.register(.listCell(.pairButton), forCellReuseIdentifier: .listCell(.pairButton))
        tableView.tableHeaderView = header
        tableView.tableFooterView = footer
        footer.isLoading = true
        
        let imageView = UIImageView(image: .init(named: "missing_song_artwork_generic_proxy"))
        imageView.kf.setImage(with: URL(string: UIDevice.current.userInterfaceIdiom == .pad ? playlist.photo?.photo1200 : playlist.photo?.photo600))
        imageView.add(to: header)
        imageView.autoCenterInSuperview()
        imageView.autoSetDimensions(to: .identity((view.bounds.width / 2) - 24))
        imageView.drawBorder(12, width: 0)
        
        let titleLabel = UILabel()
        titleLabel.add(to: header)
        titleLabel.autoPinEdge(.top, to: .bottom, of: imageView, withOffset: 16)
        titleLabel.text = playlist.title
        titleLabel.textAlignment = .center
        titleLabel.autoAlignAxis(toSuperviewAxis: .vertical)
        titleLabel.autoSetDimension(.height, toSize: 18)
        titleLabel.font = .systemFont(ofSize: 15, weight: .medium)
        titleLabel.textColor = .secondaryLabel
        
        tableView.separatorStyle = .none
        tableView.alwaysBounceVertical = true
    }
    
    func getPlaylists(isPaginate: Bool = false) throws {
        var parametersAudio: Parameters = [
            "user_id" : currentUserId,
            "playlist_id" : playlist.id!,
            "count" : 50,
            "offset": isPaginate ? self.audioItems.count : 0
        ]
        
        try ApiV2.method("audio.get", parameters: &parametersAudio, apiVersion: "5.90").done { result in
            
            self.isPageNeed = result["response"]["count"].intValue > self.audioItems.count
            
            let items = result["response"]["items"].arrayValue
            
            if isPaginate {
                self.audioItems.append(contentsOf: items.compactMap { AudioPlayerItem(fromJSON: $0) }.uniqued())
            } else {
                self.audioItems.removeAll()
                self.audioItems.insert(contentsOf: items.compactMap { AudioPlayerItem(fromJSON: $0) }.uniqued(), at: 0)
            }
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
    
    @objc func updatePlayingItem(_ notification: Notification) {
        guard let item = notification.userInfo?["item"] as? AudioPlayerItem else { return }
        guard let indexPath = getIndexPath(byItem: item) else { return }
        updatePlayItem(byIndexPath: indexPath)
    }
}

extension PlaylistViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        footer.loadingText = audioItems.isEmpty ? "Плейлист пустой" : "Аудиозаписи загружены"
        return section == 0 ? 1 : audioItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: .listCell(.pairButton), for: indexPath) as? VKPairButtonViewCell else { return UITableViewCell() }
            cell.delegate = self
            return cell
        } else {
            let audio = audioItems[indexPath.row]
            guard let cell = tableView.dequeueReusableCell(withIdentifier: .listCell(.miniAudio), for: indexPath) as? VKMiniAudioViewCell else { return UITableViewCell() }
            cell.configure(with: audio)
            cell.indexLabel.text = "\(indexPath.row + 1)"
            cell.delegate = self
            return cell
        }
    }
}

extension PlaylistViewController: PairButtonDelegate {
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

extension PlaylistViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        48
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
