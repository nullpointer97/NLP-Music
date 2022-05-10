//
//  NLPAllPlaylistsViewController.swift
//  NLPMusic
//
//  Created by Ярослав Стрельников on 02.04.2022.
//  Copyright (c) 2022 Extended Team. All rights reserved.
//

import UIKit
import Alamofire
import ObjectMapper
import MaterialComponents
import SkeletonView

final class NLPAllPlaylistsViewController: NLPBaseTableViewController {

    // MARK: - Public properties -

    var presenter: NLPAllPlaylistsPresenterInterface!

    // MARK: - Lifecycle -

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTable()
        
        do {
            try presenter.onGetPlaylists(isPaginate: false)
        } catch {
            print(error)
        }
        
        observables.append(UserDefaults.standard.observe(UInt32.self, key: "_accentColor") {
            _ = $0
            self.reload()
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        asdk_navigationViewController?.navigationBar.titleTextAttributes?[.foregroundColor] = UIColor.label.withAlphaComponent(1)
    }

    override func setupTable(style: UITableView.Style = .plain) {
        super.setupTable()

        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.showAnimatedGradientSkeleton()
        tableView.startSkeletonAnimation()
    }
    
    override func didOpenMenu(playlist cell: NLPBaseViewCell<Playlist>) {
        super.didOpenMenu(playlist: cell)
        
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let playlist = presenter.playlistItems[indexPath.row]
        
        let removeAction = MDCActionSheetAction(title: "Удалить", image: UIImage(named: "delete_outline_28")?.tint(with: .label)) { [weak self] _ in
            guard let self = self else { return }
            do {
                try self.presenter.onRemovePlaylist(playlist: playlist)
            } catch {
                self.showEventMessage(.error, message: error.localizedDescription)
            }
        }
        removeAction.tintColor = .systemRed
        removeAction.titleColor = .systemRed

        openMenu(actions: [removeAction], title: "Меню плейлиста")
    }
    
    override func didFinishLoad() {
        super.didFinishLoad()
        footer.loadingText = presenter.playlistItems.isEmpty ? "У Вас нет плейлистов" : getStringByDeclension(number: presenter.playlistItems.count, arrayWords: Localization.playlistCount)
    }
    
    override func reloadAudioData() {
        super.reloadAudioData()
        
        do {
            try presenter.onGetPlaylists(isPaginate: false)
        } catch {
            print(error)
        }
    }
    
    @objc(tableView:willNeedPaginate:forRowAt:)
    override func tableView(_ tableView: UITableView, willNeedPaginate cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.item == presenter.playlistItems.count - 5 && presenter.isPageNeed {
            do {
                try presenter.onGetPlaylists(isPaginate: true)
            } catch {
                print(error)
            }
        }
    }
}

// MARK: - Extensions -

extension NLPAllPlaylistsViewController: NLPAllPlaylistsViewInterface {
    func didRemovePlaylist(playlist: Playlist) {
        guard let row = presenter.playlistItems.firstIndex(of: playlist) else { return }
        
        DispatchQueue.main.async { [self] in
            presenter.playlistItems.remove(at: row)
            tableView.deleteRows(at: [IndexPath(row: row, section: 0)], with: .left)
        }
    }
}

extension NLPAllPlaylistsViewController: SkeletonTableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return presenter.playlistItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let playlist = presenter.playlistItems[indexPath.row]
        guard let cell = tableView.dequeueReusableCell(withIdentifier: .listCell(.listPlaylist), for: indexPath) as? NLPPlaylistListViewCell else { fatalError() }
        
        cell.configure(with: playlist)
        cell.menuDelegate = self
        return cell
    }
    
    func numSections(in collectionSkeletonView: UITableView) -> Int {
        return 1
    }
    
    func collectionSkeletonView(_ skeletonView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 25
    }
    
    func collectionSkeletonView(_ skeletonView: UITableView, cellIdentifierForRowAt indexPath: IndexPath) -> ReusableCellIdentifier {
        return .listCell(.listPlaylist)
    }
    
    func collectionSkeletonView(_ skeletonView: UITableView, skeletonCellForRowAt indexPath: IndexPath) -> UITableViewCell? {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: .listCell(.listPlaylist), for: indexPath) as? NLPPlaylistListViewCell else { fatalError() }
        return cell
    }
    
    func collectionSkeletonView(_ skeletonView: UITableView, prepareCellForSkeleton cell: UITableViewCell, at indexPath: IndexPath) {
        let cell = cell as? NLPPlaylistListViewCell
        cell?.isSkeletonable = true
    }
}

extension NLPAllPlaylistsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let playlist = presenter.playlistItems[indexPath.row]
        tableView.deselectRow(at: indexPath, animated: true)
        
        presenter.onOpenPlaylist(playlist)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 84
    }
}
