//
//  NLPPlaylistViewController.swift
//  NLPMusic
//
//  Created by Ярослав Стрельников on 02.04.2022.
//  Copyright (c) 2022 Extended Team. All rights reserved.
//

import UIKit
import MaterialComponents

final class NLPPlaylistViewController: NLPBaseTableViewController {
    let playlist: Playlist
    var headerView: StickyHeaderView!

    // MARK: - Public properties -

    var presenter: NLPPlaylistPresenterInterface!

    init(_ playlist: Playlist) {
        self.playlist = playlist
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }

    // MARK: - Lifecycle -

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = playlist.title
        
        setupTable()
        
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(image: .init(named: "download_outline_28")?.tint(with: .getAccentColor(fromType: .common)), style: .done, target: self, action: #selector(downloadAll)),
        ]
        
        do {
            try presenter.onGetPlaylists(isPaginate: false, playlistId: playlist.id)
        } catch {
            print(error)
            self.error(message: "Произошла ошибка")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        asdk_navigationViewController?.navigationBar.titleTextAttributes?[.foregroundColor] = UIColor.label.withAlphaComponent(0)
        navigationItem.largeTitleDisplayMode = .never
    }
    
    override func didOpenMenu(audio cell: NLPBaseViewCell<AudioPlayerItem>) {
        super.didOpenMenu(audio: cell)
        
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let item = audioItems[indexPath.row]
        
        let saveAction = MDCActionSheetAction(title: "Сохранить", image: UIImage(named: "download_outline_28")?.tint(with: .label)) { [weak self] _ in
            guard let self = self else { return }
            self.didSaveAudio(item, indexPath: indexPath)
        }
        saveAction.tintColor = .label
        saveAction.titleColor = .label
        
        let addAction = MDCActionSheetAction(title: "Добавить к себе", image: UIImage(named: "add_outline_24")?.tint(with: .label)) { [weak self] _ in
            guard let self = self else { return }
            do {
                try self.presenter.onAddAudio(audio: item)
            } catch {
                self.showEventMessage(.error, message: error.localizedDescription)
            }
        }
        addAction.tintColor = .label
        addAction.titleColor = .label
        
        let removeInCacheAction = MDCActionSheetAction(title: "Удалить из кэша", image: UIImage(named: "delete_outline_28")?.tint(with: .systemRed)) { [weak self] _ in
            guard let self = self else { return }
            self.didRemoveAudio(item, indexPath: indexPath)
        }
        removeInCacheAction.tintColor = .systemRed
        removeInCacheAction.titleColor = .systemRed
        openMenu(fromItem: item, actions: item.isDownloaded ? [addAction, removeInCacheAction] : [addAction, saveAction])
    }

    override func setupTable(style: UITableView.Style = .plain) {
        super.setupTable()
        let year = playlist.year ?? 0
        let artist = playlist.mainArtists?.first?.name ?? ""

        headerView = StickyHeaderView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: StickyHeaderView.getHeight(isArtistAvailable: !artist.isEmpty, isYearAvailable: year > 0)))
        headerView.imageView.shadowAlpha = 0

        tableView.tableHeaderView = headerView
        
        dataSource?.footerLineText = playlist.plays > 0 ? getStringByDeclension(number: playlist.plays, arrayWords: Localization.plays) : getStringByDeclension(number: playlist.count, arrayWords: Localization.audioCount)
        
        addRefreshControl()
        
        tableView.showAnimatedGradientSkeleton()
        tableView.startSkeletonAnimation()
    }
    
    override func tableView(_ tableView: UITableView, willNeedPaginate cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == audioItems.count && presenter.isPageNeed {
            do {
                try presenter.onGetPlaylists(isPaginate: true, playlistId: playlist.id)
            } catch {
                print(error)
                self.error(message: "Произошла ошибка")
            }
        }
    }
    
    override func didFinishLoad() {
        super.didFinishLoad()
        
        if let imageUrl = URL(string: playlist.photo?.photo300) {
            headerView.imageView.imageView.kf.setImage(with: imageUrl)
        } else {
            headerView.imageView.imageView.image = .init(named: "playlist_outline_56")
        }
        
        headerView.titleLabel.text = playlist.title
        headerView.subtitleLabel.text = playlist.mainArtists?.first?.name
        headerView.subtitleSecondLabel.text = playlist.year?.stringValue
        
        headerView.imageView.imageView.hideSkeleton()
        headerView.titleLabel.hideSkeleton()
        headerView.subtitleLabel.hideSkeleton()
        headerView.subtitleSecondLabel.hideSkeleton()
    }
    
    override func reloadAudioData() {
        do {
            try presenter.onGetPlaylists(isPaginate: false, playlistId: playlist.id)
        } catch {
            print(error)
            self.error(message: "Произошла ошибка")
        }
    }
    
    @objc func downloadAll() {
        navigationItem.rightBarButtonItems?.first?.isEnabled = false
        let backgroundQ = DispatchQueue.global(qos: .userInteractive)
        let group = DispatchGroup()

        let completion = BlockOperation {
            print("all done")
            self.navigationItem.rightBarButtonItems?.first?.isEnabled = true
        }
        
        for item in audioItems {
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
        }

        OperationQueue.main.addOperation(completion)
    }
}

// MARK: - Extensions -

extension NLPPlaylistViewController: NLPPlaylistViewInterface {
}
