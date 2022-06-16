//
//  DataSourceBuilder.swift
//  VKM
//
//  Created by Ярослав Стрельников on 25.05.2021.
//

import Foundation
import UIKit
import ObjectMapper

class DataSourceBuilder<T: UITableView, D: Mappable, V: VKMBaseCell<D>>: NSObject, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 0
    }
}

final class AudioDataSourceBuilder<P: Mappable>: DataSourceBuilder<UITableView, AudioItem,
                                                                    VKMBaseCell<AudioItem>>,
                                                  UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    var items: [[Any]] = .empty {
        didSet {
            tableView.reloadData()
        }
    }
    var count: Int = 0
    var tableView: UITableView
    
    init(audios: [AudioItem], playlists: [Playlist], count: Int = 0, tableView: UITableView) {
        self.items.append(playlists)
        self.items.append(audios)
        self.count = count
        self.tableView = tableView
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 1 ? items[1].count : items[0].count > 0 ? 1 : 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            guard let cell: PlaylistsViewCell = tableView.dequeue(for: indexPath) else { return UITableViewCell() }
            cell.setCollectionViewDataSourceDelegate(dataSourceDelegate: self, forRow: indexPath.row)
            cell.delegate = tableView.parentViewController as? VKMBaseViewController<UIListView>
            return cell
        case 1:
            guard let cell: AudioViewCell = tableView.dequeue(for: indexPath) else { return UITableViewCell() }
            cell.configure(with: items[1][indexPath.row] as! AudioItem)
            cell.delegate = tableView.parentViewController as? VKMBaseViewController<UIListView>
            return cell
        default:
            return UITableViewCell()
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items[0].count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withClass: PlaylistViewCell.self, for: indexPath)
        cell.configure(with: items[0][indexPath.item] as! Playlist)
        cell.delegate = self.tableView.parentViewController as? AudioViewController
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return .custom(147, 206)
    }
}

final class PlaylistDataSourceBuilder<P: Mappable>: DataSourceBuilder<UITableView, AudioItem, VKMBaseCell<AudioItem>> {
    var items: [AudioItem] = .empty {
        didSet {
            tableView.reloadData()
        }
    }
    var tableView: UITableView
    var currentPlaylist: Playlist
    
    init(audios: [AudioItem], currentPlaylist: Playlist, tableView: UITableView) {
        self.items.append(contentsOf: audios)
        self.currentPlaylist = currentPlaylist
        self.tableView = tableView
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 1 : items.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            guard let cell: PlaylistHeaderViewCell = tableView.dequeue(for: indexPath) else { return UITableViewCell() }
            cell.configure(with: currentPlaylist)
            return cell
        case 1:
            guard let cell: PlaylistAudioViewCell = tableView.dequeue(for: indexPath) else { return UITableViewCell() }
            cell.configure(with: items[indexPath.row])
            cell.indexLabel.text = (indexPath.row + 1).string
            cell.indexLabel.sizeToFit()
            cell.delegate = tableView.parentViewController as? VKMBaseViewController<UICollectionView>
            return cell
        default:
            return UITableViewCell()
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
}
