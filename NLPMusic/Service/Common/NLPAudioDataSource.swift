//
//  VKAudioService.swift
//  vkmusic
//
//  Created by Ярослав Стрельников on 03.02.2022.
//  Copyright © 2022 NP-Team. All rights reserved.
//

import Foundation
import CoreStore
import UIKit
import SkeletonView

protocol NLPAudioTableDelegate: AnyObject {
    func tableView(_ tableView: UITableView, willNeedPaginate cell: UITableViewCell, forRowAt indexPath: IndexPath)
}

protocol NLPAudioDataSourceActionsDelegate: AnyObject {
    func didRemoveAudio(_ item: AudioPlayerItem)
    func didAddAudio(_ item: AudioPlayerItem)
    func didSaveAudio(_ item: AudioPlayerItem)
    func didRemoveFromCacheAudio(_ item: AudioPlayerItem)
}

final class NLPAudioDataSource: NSObject, SkeletonTableViewDataSource, UITableViewDelegate {
    init(items: [AudioPlayerItem], parent: NLPBaseTableViewController?) {
        self.items = items
        self.parent = parent
    }
    
    var items: [AudioPlayerItem] {
        didSet {
            parent?.reload()
        }
    }
    
    var isCurrentUser: Bool = false
    weak var actionDelegate: NLPAudioDataSourceActionsDelegate?
    
    var footerLineText: String? = "" {
        didSet {
            parent?.footer.loadingText = footerLineText
        }
    }
    
    private var parent: NLPBaseTableViewController?
    
    weak var delegate: NLPAudioTableDelegate?
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return items.count > 0 ? 2 : 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count > 0 ? section == 0 ? 1 : items.count : 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items[indexPath.row]

        if indexPath.section == 0 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: .listCell(.folder), for: indexPath) as? NLPFolderViewCell else { return UITableViewCell() }
            cell.configureShuffleButton()
            
            cell.delegate = parent
            
            return cell
        } else {
            let audio = items[indexPath.row]
            guard let cell = tableView.dequeueReusableCell(withIdentifier: .listCell(.audio), for: indexPath) as? NLPAudioViewCell else { return UITableViewCell() }
            cell.configure(with: audio)
            
            cell.delegate = parent
            cell.menuDelegate = parent
            
            cell.setDownloadProcess(item.downloadStatus, indexPath: indexPath)
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        60
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        delegate?.tableView(tableView, willNeedPaginate: cell, forRowAt: indexPath)
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let item = items[indexPath.row]
        let save = UIContextualAction(style: .normal, title: .localized(.save)) { [weak self] (action, view, completionHandler) in
            self?.actionDelegate?.didSaveAudio(item)
            completionHandler(true)
        }
        save.backgroundColor = .systemGreen

        // Trash action
        let addToLibrary = UIContextualAction(style: .destructive, title: .localized(.addToLibrary)) { [weak self] (action, view, completionHandler) in
            self?.actionDelegate?.didAddAudio(item)
            completionHandler(true)
        }
        addToLibrary.backgroundColor = .systemBlue

        // Unread action
        let delete = UIContextualAction(style: .normal, title: .localized(.delete)) { [weak self] (action, view, completionHandler) in
            self?.actionDelegate?.didRemoveAudio(item)
            completionHandler(true)
        }
        delete.backgroundColor = .systemRed
        
        let deleteFromCache = UIContextualAction(style: .normal, title: .localized(.deleteFromCache)) { [weak self] (action, view, completionHandler) in
            self?.actionDelegate?.didRemoveFromCacheAudio(item)
            completionHandler(true)
        }
        deleteFromCache.backgroundColor = .systemOrange
        
        let configuration: UISwipeActionsConfiguration
        
        if isCurrentUser {
            configuration = UISwipeActionsConfiguration(actions: item.isDownloaded ? [delete, deleteFromCache].reversed() : [save, delete].reversed())
        } else {
            configuration = UISwipeActionsConfiguration(actions: item.isDownloaded ? [addToLibrary, deleteFromCache].reversed() : [addToLibrary, save].reversed())
        }
        
        return configuration
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let headerView = parent?.tableView.tableHeaderView as? StickyHeaderView else { return }
        headerView.scrollViewDidScroll(scrollView)

        let height = headerView.bounds.height - 68
        
        var progress = (scrollView.contentOffset.y + 32) / height
        progress = min(progress, 1)

        if progress <= 1 && progress >= 0 {
            UIView.animate(withDuration: 0.05, delay: 0, options: [.allowUserInteraction, .beginFromCurrentState]) { [weak self] in
                self?.parent?.asdk_navigationViewController?.navigationBar.titleTextAttributes?[.foregroundColor] = UIColor.label.withAlphaComponent(progress)
                headerView.imageView.alpha = 1 - progress
                headerView.titleLabel.alpha = 1 - progress
                headerView.subtitleLabel.alpha = 1 - progress
                headerView.subtitleSecondLabel.alpha = 1 - progress
            }
        }
    }
    
    func numSections(in collectionSkeletonView: UITableView) -> Int {
        return 2
    }
    
    func collectionSkeletonView(_ skeletonView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 1 : 25
    }
    
    func collectionSkeletonView(_ skeletonView: UITableView, cellIdentifierForRowAt indexPath: IndexPath) -> ReusableCellIdentifier {
        return indexPath.section == 0 ? .listCell(.folder) : .listCell(.audio)
    }
    
    func collectionSkeletonView(_ skeletonView: UITableView, skeletonCellForRowAt indexPath: IndexPath) -> UITableViewCell? {
        if indexPath.section == 0 {
            guard let cell = skeletonView.dequeueReusableCell(withIdentifier: .listCell(.folder), for: indexPath) as? NLPFolderViewCell else { return UITableViewCell() }
            return cell
        } else {
            guard let cell = skeletonView.dequeueReusableCell(withIdentifier: .listCell(.audio), for: indexPath) as? NLPAudioViewCell else { return UITableViewCell() }
            return cell
        }
    }
    
    func collectionSkeletonView(_ skeletonView: UITableView, prepareCellForSkeleton cell: UITableViewCell, at indexPath: IndexPath) {
        if indexPath.section == 0 {
            let cell = cell as? NLPFolderViewCell
            cell?.isSkeletonable = true
        } else {
            let cell = cell as? NLPAudioViewCell
            cell?.isSkeletonable = true
        }
    }
}

final class VKAudioDataStackService: NSObject {
    static let conversationsCount = UserDefaults.standard.integer(forKey: "conversationsCount")
    
    static let audios: ListPublisher<AudioItem> = {
        let list = dataStack.publishList(
            From<AudioItem>(),
            OrderBy<AudioItem>(.descending("date"))
        )
        return list
    }()
    
    static func getAudios(where: Where<AudioItem> = Where<AudioItem>()) -> ListPublisher<AudioItem> {
        let list = dataStack.publishList(
            From<AudioItem>(),
            `where`,
            OrderBy<AudioItem>(.descending("date"))
        )
        return list
    }
    
    static let dataStack: DataStack = {
        let dataStack = DataStack(CoreStoreSchema(modelVersion: "V1", entities: [Entity<AudioItem>("AudioItem")]))
        try! dataStack.addStorageAndWait(SQLiteStore(fileName: "AudioItem.sqlite", localStorageOptions: .recreateStoreOnModelMismatch))
        return dataStack
    }()
    
    static func removeDataStack(success: @escaping ((AudioItem.Type) -> Void), failed: @escaping ((CoreStoreError) -> Void)) throws {
        dataStack.perform { transaction in
            try transaction.deleteAll(From<AudioItem>())
        } completion: { result in
            switch result {
            case .success:
                success(AudioItem.self)
            case .failure(let coreStoreError):
                failed(coreStoreError)
            }
        }
    }
}

final class DataStackService<T: CoreStoreObject>: NSObject {
    let objectsCount = UserDefaults.standard.integer(forKey: "\(T.self)Count")
    
    func getObjects(with predicate: NSPredicate? = nil) -> ListPublisher<T> {
        let list: ListPublisher<T>
        list = dataStack.publishList(
            From<T>(),
            OrderBy<T>(
                .descending("date")
            ),
            Tweak { request in
                request.predicate = predicate
            }
        )
        return list
    }
    
    let dataStack: DataStack = {
        let dataStack = DataStack(CoreStoreSchema(modelVersion: "V1", entities: [Entity<T>("\(T.self)")]))
        try! dataStack.addStorageAndWait(SQLiteStore(fileName: "\(T.self).sqlite", localStorageOptions: .recreateStoreOnModelMismatch))
        return dataStack
    }()
    
    func removeDataStack(success: @escaping ((T.Type) -> Void), failed: @escaping ((CoreStoreError) -> Void)) throws {
        dataStack.perform { transaction in
            try transaction.deleteAll(From<T>())
        } completion: { result in
            switch result {
            case .success:
                success(T.self)
            case .failure(let coreStoreError):
                failed(coreStoreError)
            }
        }
    }
}

final class EditableDataSource<T: DynamicObject>: DiffableDataSource.TableViewAdapter<T> {
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return false
    }
}
