//
//  NLPBaseTableViewController.swift
//  NLPMusic
//
//  Created by Ярослав Стрельников on 02.04.2022.
//  Copyright © 2022 NP-Team. All rights reserved.
//

import Foundation
import UIKit
import CoreStore
import MaterialComponents
import SkeletonView

open class NLPBaseTableViewController: NLPBaseViewController, MenuDelegate, NLPAudioTableDelegate {
    var tableView: UITableView!
    var footer: UITableViewFooter = UITableViewFooter(frame: .init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 80))
    lazy var refreshControl = UIRefreshControl()
    var pullToRefresh: DRPRefreshControl!
    
    var tableId = 100
    
    var audioItems: [AudioPlayerItem] = [] {
        didSet {
            dataSource?.items = audioItems
        }
    }
    var vkTabBarController: NLPTabController? {
        return tabBarController as? NLPTabController
    }
    
    var dataSource: NLPAudioDataSource?
        
    let downloadService = AudioDownloadManager()
    lazy var session: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: "downloadAudio_\(Int.random(in: 1000...9999))")
        config.timeoutIntervalForRequest = 20
        
        let session = URLSession(configuration: config, delegate: self, delegateQueue: .main)
        return session
    }()
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        downloadService.session = session
        view.showAnimatedGradientSkeleton()
        
        NotificationCenter.default.addObserver(self, selector: #selector(onItemEdited(_:)), name: NSNotification.Name("didRemoveAudio"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didCacheClean(_:)), name: NSNotification.Name("didCleanCache"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(onPlayerChangeState(_:)), name: NSNotification.Name("didStartPlaying"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onPlayerChangeState(_:)), name: NSNotification.Name("didPausePlaying"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onPlayerChangeState(_:)), name: NSNotification.Name("didStopPlaying"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onPlayerChangeState(_:)), name: NSNotification.Name("didResumePlaying"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onPlayerChangeState(_:)), name: NSNotification.Name("didDownloadAudio"), object: nil)
        
        observables.append(UserDefaults.standard.observe(UInt32.self, key: "_accentColor") {
            _ = $0            
            let cell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? NLPPairButtonViewCell
            cell?.playButton.setTitleColor(.getAccentColor(fromType: .common), for: .normal)
            cell?.shuffleButton.setTitleColor(.getAccentColor(fromType: .common), for: .normal)
            
            cell?.playButton.setImage(.init(named: "play.fill")?.resize(toWidth: 20)?.resize(toHeight: 20)?.tint(with: .getAccentColor(fromType: .common)), for: .normal)
            cell?.shuffleButton.setImage(.init(named: "shuffle_24")?.resize(toWidth: 20)?.resize(toHeight: 20)?.tint(with: .getAccentColor(fromType: .common)), for: .normal)
            
            self.reload()
        })
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if tableView.sk.isSkeletonActive {
            if !audioItems.isEmpty {
                tableView.hideSkeleton()
            } else {
                tableView.showAnimatedGradientSkeleton()
            }
        } else {
            reload()
        }
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        reload()
    }
    
    override func perform<AudioSectionItem>(from cell: NLPBaseViewCell<AudioSectionItem>) {
        shuffleAll()
    }
    
    override func didTap<T>(_ cell: NLPBaseViewCell<T>) {
        super.didTap(cell)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [self] in
            guard let indexPath = tableView.indexPath(for: cell), let player = AudioService.instance.player else { return }
            let selectedItem = audioItems[indexPath.row]
            
            switch player.state {
            case .buffering:
                if player.currentItem == selectedItem {
                    vkTabBarController?.openPopup(animated: true)
                } else {
                    player.play(items: audioItems, startAtIndex: indexPath.row)
//                    vkTabBarController?.playerViewController.queueItems = player.queue?.queue ?? []
                }
            case .playing:
                if player.currentItem == selectedItem {
                    vkTabBarController?.openPopup(animated: true)
                } else {
                    player.play(items: audioItems, startAtIndex: indexPath.row)
//                    vkTabBarController?.playerViewController.queueItems = player.queue?.queue ?? []
                }
            case .paused:
                if player.currentItem == selectedItem {
                    player.resume()
                } else {
                    player.play(items: audioItems, startAtIndex: indexPath.row)
//                    vkTabBarController?.playerViewController.queueItems = player.queue?.queue ?? []
                }
            case .stopped:
                DispatchQueue.main.async { [self] in
                    player.play(items: audioItems, startAtIndex: indexPath.row)
//                    vkTabBarController?.playerViewController.queueItems = player.queue?.queue ?? []
                }
            case .waitingForConnection:
                log("player wait connection", type: .warning)
            case .failed(let error):
                log(error.localizedDescription, type: .error)
            }
        }
    }
    
    @objc func tableView(_ tableView: UITableView, willNeedPaginate cell: UITableViewCell, forRowAt indexPath: IndexPath) { }
    
    func didOpenMenu(audio cell: NLPBaseViewCell<AudioPlayerItem>) { }
    
    func didOpenMenu(playlist cell: NLPBaseViewCell<Playlist>) { }
    
    func setupTable(style: UITableView.Style = .plain) {
        tableView = UITableView(frame: view.frame, style: style)
        tableView.isSkeletonable = true
        tableView.add(to: view)
        tableView.autoPinEdgesToSuperviewEdges()
        tableView.register(.listCell(.audio), forCellReuseIdentifier: .listCell(.audio))
        tableView.register(.listCell(.pairButton), forCellReuseIdentifier: .listCell(.pairButton))
        tableView.register(.listCell(.listPlaylist), forCellReuseIdentifier: .listCell(.listPlaylist))
        tableView.register(.listCell(.smallUser), forCellReuseIdentifier: .listCell(.smallUser))
        tableView.register(.listCell(.bigUser), forCellReuseIdentifier: .listCell(.bigUser))
        tableView.register(.listCell(.folder), forCellReuseIdentifier: .listCell(.folder))

        tableView.tableFooterView = footer
        footer.isLoading = false
        
        tableView.separatorStyle = .none
        tableView.alwaysBounceVertical = true
        
        dataSource = NLPAudioDataSource(items: audioItems, parent: self)
        dataSource?.delegate = self
        
        tableView.delegate = dataSource
        tableView.dataSource = dataSource
        
        pullToRefresh = DRPRefreshControl()
        pullToRefresh.loadingSpinner.colorSequence = [.color(from: 0x99A2AD)]
        pullToRefresh.loadingSpinner.lineWidth = 2.5
        pullToRefresh.loadingSpinner.maximumArcLength = (2 * .pi) - .pi / 4
        pullToRefresh.loadingSpinner.minimumArcLength = 0
        
        
        for operation in vkTabBarController?.downloadManager.operations ?? [:] {
            if let item = operation.value.item, audioItems.indices.contains(audioItems.firstIndex(of: item) ?? 0) {
                if operation.value.isExecuting {
                    audioItems[audioItems.firstIndex(of: item) ?? 0].downloadStatus = .inProgress
                }
                
                if operation.value.isFinished {
                    audioItems[audioItems.firstIndex(of: item) ?? 0].downloadStatus = .completed
                }
            }
        }
    }
    
    func addRefreshControl() {
        pullToRefresh.add(to: tableView) { [weak self] in
            self?.reloadAudioData()
        }
    }
    
    func startRefreshing() {
        footer.isLoading = true
    }
    
    func endRefreshing() {
        pullToRefresh.endRefreshing()
    }

    func didFinishLoad() {
        footer.isLoading = false
        pullToRefresh.endRefreshing()
        tableView.hideSkeleton(reloadDataAfter: true, transition: .crossDissolve(0.2))
        
        tableView.reloadData()
    }

    func error(message: String) {
        footer.loadingText = message
    }
    
    @objc func reload() {
        DispatchQueue.main.async { [self] in
            tableView.reloadData()
        }
    }
    
    @objc func onItemEdited(_ notification: Notification) {
        guard notification.userInfo?["item"] is AudioPlayerItem else { return }
        
        reload()
    }
    
    @objc func updatePlayingItem(_ notification: Notification) {
        guard let item = notification.userInfo?["item"] as? AudioPlayerItem else { return }
        guard let indexPath = getIndexPath(byItem: item) else { return }
        updatePlayItem(byIndexPath: indexPath)
    }
    
    @objc func onPlayerChangeState(_ notification: Notification) {
        guard let item = notification.userInfo?["item"] as? AudioPlayerItem else { return }
        guard let row = audioItems.firstIndex(of: item) else { return }
        guard let cell = tableView.cellForRow(at: IndexPath(row: row, section: 1)) as? NLPAudioViewCell else { return }
        
        DispatchQueue.main.async {
            cell.setAnimation(isPlaying: item.isPlaying, isPaused: item.isPaused)
        }
    }
    
    @objc func didCacheClean(_ notification: Notification) {
        reload()
    }
    
    @objc func reloadAudioData() {
        pullToRefresh.endRefreshing()
    }
}

extension NLPBaseTableViewController: URLSessionDownloadDelegate {
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        var documentsDirectoryURL: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("music_cache")

        guard let sourceURL = downloadTask.originalRequest?.url else {
            return
        }
        
        guard let download = downloadService.activeDownloads[sourceURL] else { return }
        downloadService.activeDownloads[sourceURL] = nil
        
        guard let url = URL(string: download.track.url) else { return }
        let destinationUrl = documentsDirectoryURL.appendingPathComponent("\(download.track.songName ?? "unknown").\(url.pathExtension)")

        do {
            try FileManager.default.moveItem(at: location, to: destinationUrl)
            try AudioDataStackService.dataStack.perform { transaction in
                do {
                    _ = try transaction.importUniqueObject(Into<AudioItem>(), source: download.track)
                    NotificationCenter.default.post(name: NSNotification.Name("didDownloadAudio"), object: nil, userInfo: ["item": download.track])
                } catch {
                    print(error.localizedDescription)
                }
            }
        } catch {
            print(error)
        }
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard
            let url = downloadTask.originalRequest?.url,
            let download = downloadService.activeDownloads[url]  else {
            return
        }

        download.progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
    }
}

extension NLPBaseTableViewController: AudioItemActionDelegate {
    func didSaveAudio(_ item: AudioPlayerItem, indexPath: IndexPath) {
        let backgroundQ = DispatchQueue.global(qos: .userInteractive)
        let group = DispatchGroup()

        let completion = BlockOperation {
            print("all done")
        }
        
        if !item.isDownloaded, let url = URL(string: item.url) {
            vkTabBarController?.downloadManager.identifier = item.id
            vkTabBarController?.downloadManager.item = item
            vkTabBarController?.downloadManager.tableId = item.id
            vkTabBarController?.downloadManager.row = audioItems.firstIndex(of: item) ?? 0
            
            item.downloadStatus = .inProgress
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.tableView.reloadRows(at: [IndexPath(row: self.audioItems.firstIndex(of: item) ?? 0, section: 1)], with: .none)
            }
            
            let operation = vkTabBarController?.downloadManager.queueDownload(url)
            
            group.enter()
            backgroundQ.async(group: group) {
                operation?.onProgress = { (row, tableId, progress) in
                    print("Item \(item.id) progress: \(progress)")
                    DispatchQueue.main.async {
                        let indexpath = IndexPath(row: row, section: 1)
                        let cell = self.tableView.cellForRow(at: indexpath) as? NLPAudioViewCell
                        print("downloading for cell \(String(describing: cell?.tag))")
                        if progress <= 1.0 {
                            let progressRing = cell?.downloadProgressRingView
                            progressRing?.setProgress(value: CGFloat(progress * 100), animationDuration: 0.3)
                            
                            if progress == 1.0 {
                                self.audioItems[row].downloadStatus = .completed
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    self.tableView.reloadRows(at: [indexpath], with: .none)
                                }
                            }
                        } else {
                            if progress >= 1.0 {
                                self.audioItems[row].downloadStatus = .completed
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    self.tableView.reloadRows(at: [indexpath], with: .none)
                                }
                            }
                        }
                    }
                }
                group.leave()
            }
            
            group.notify(queue: DispatchQueue.main) {
                print("All Done")
                self.tableView.reloadData()
            }
            
            completion.addDependency(operation!)
        }

        OperationQueue.main.addOperation(completion)
    }
    
    
    func didRemoveAudio(_ item: AudioPlayerItem, indexPath: IndexPath) {        
        do {
            try item.removeAudio()
        } catch {
            print(error)
        }
    }
}

extension NLPBaseTableViewController: PairButtonDelegate {
    func didPlayAll(_ cell: NLPPairButtonViewCell) {
        guard let player = AudioService.instance.player, audioItems.count > 0 else { return }
        
        if player.currentItem != nil || player.currentItem?.isPaused ?? false || player.currentItem?.isPlaying ?? false {
            AudioService.instance.player?.stop()
        }
        
        player.mode = .normal
        playing(player)
    }
    
    func didShuffleAll(_ cell: NLPPairButtonViewCell) {
        guard let player = AudioService.instance.player, audioItems.count > 0 else { return }
        
        if player.currentItem != nil || player.currentItem?.isPaused ?? false || player.currentItem?.isPlaying ?? false {
            AudioService.instance.player?.stop()
        }
        
        playing(player, true)
        player.mode = .shuffle
    }
    
    func shuffleAll() {
        guard let player = AudioService.instance.player, audioItems.count > 0 else { return }
        
        if player.currentItem != nil || player.currentItem?.isPaused ?? false || player.currentItem?.isPlaying ?? false {
            AudioService.instance.player?.stop()
        }
        
        playing(player, true)
        player.mode = .shuffle
    }
    
    private func playing(_ player: AudioPlayer, _ isShuffle: Bool = false) {
        if let playerViewController = vkTabBarController?.playerViewController {
            vkTabBarController?.presentPopupBar(withContentViewController: playerViewController, animated: true, completion: nil)
        }
//        vkTabBarController?.playerViewController.queueItems = player.queue?.queue ?? []
        player.play(items: audioItems, startAtIndex: isShuffle ? Int.random(in: 0...audioItems.count - 1) : 0)
    }
}

var verticalOffset: CGFloat {
    UIDevice.current.isLargeDevice ? 103 : 83
}

extension UIDevice {
    var isLargeDevice: Bool {
        return UIDevice.current.modelName.contains("iPhone X") || UIDevice.current.modelName.contains("iPhone 11") || UIDevice.current.modelName.contains("iPhone 12") || UIDevice.current.modelName.contains("iPhone 10") || UIDevice.current.modelName.contains("iPhone 13")
    }
}
