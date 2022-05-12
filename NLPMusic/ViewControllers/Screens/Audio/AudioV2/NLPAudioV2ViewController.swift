//
//  NLPAudioV2ViewController.swift
//  NLPMusic
//
//  Created by Ярослав Стрельников on 04.04.2022.
//  Copyright (c) 2022 Extended Team. All rights reserved.
//

import UIKit
import MaterialComponents
import SkeletonView

final class NLPAudioV2ViewController: NLPBaseTableViewController {

    // MARK: - Public properties -

    var presenter: NLPAudioV2PresenterInterface!
    var userId = currentUserId

    // MARK: - Lifecycle -

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTable()
        
        do {
            try presenter.onGetAudio(userId: userId, isPaginate: false)
        } catch {
            print(error)
            self.error(message: "Произошла ошибка")
        }
        
        observables.append(UserDefaults.standard.observe(UInt32.self, key: "_accentColor") {
            _ = $0
            self.reload()
        })
    }
    
    override func perform<AudioSectionItem>(from cell: NLPBaseViewCell<AudioSectionItem>) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        
        if indexPath.section == 0 {
            var viewController: NLPBaseTableViewController!
            
            switch indexPath.row {
            case 0:
                guard let sectionId = presenter.dataSource?[0].items[indexPath.row].blockId else { return }
                viewController = NLPSectionViewController(sectionId: sectionId)
            case 1:
                viewController = NLPAllPlaylistsWireframe().viewController
            case 2:
                viewController = NLPSavedMusicViewController()
            default:
                break
            }

            viewController.title = presenter.dataSource?[0].items[indexPath.row].title

            asdk_navigationViewController?.pushViewController(viewController, animated: true)
        } else {
            shuffleAll()
        }
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
        saveAction.isEnabled = true
        
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
        addAction.isEnabled = true
        
        let removeAction = MDCActionSheetAction(title: "Удалить", image: UIImage(named: "delete_outline_28")?.tint(with: .systemRed)) { [weak self] _ in
            guard let self = self else { return }
            do {
                try self.presenter.onRemoveAudio(audio: item)
            } catch {
                self.showEventMessage(.error, message: "Произошла ошибка при удалении")
            }
        }
        removeAction.tintColor = .systemRed
        removeAction.titleColor = .systemRed
        
        let removeInCacheAction = MDCActionSheetAction(title: "Удалить из кэша", image: UIImage(named: "delete_outline_28")?.tint(with: .systemRed)) { [weak self] _ in
            guard let self = self else { return }
            self.didRemoveAudio(item, indexPath: indexPath)
        }
        removeInCacheAction.tintColor = .systemRed
        removeInCacheAction.titleColor = .systemRed
        
        if userId == currentUserId {
            openMenu(fromItem: item, actions: item.isDownloaded ? [removeAction, removeInCacheAction] : [saveAction, removeAction])
        } else {
            openMenu(fromItem: item, actions: item.isDownloaded ? [addAction, removeInCacheAction] : [addAction, saveAction])
        }
    }
    
    override func setupTable(style: UITableView.Style = .plain) {
        super.setupTable(style: .grouped)
        
        tableView.backgroundColor = .systemBackground
        tableView.delegate = self
        tableView.dataSource = self
        
        addRefreshControl()
        
        tableView.showAnimatedSkeleton()
        tableView.startSkeletonAnimation()
    }
    
    override func reload() {
        super.reload()
        footer.loadingText = audioItems.isEmpty ? "У Вас нет аудиозаписей" : getStringByDeclension(number: audioItems.count, arrayWords: Localization.audioCount)
    }
    
    override func reloadAudioData() {
        do {
            try presenter.onGetAudio(userId: userId, isPaginate: false)
        } catch {
            print(error)
            self.error(message: "Произошла ошибка")
        }
    }
    
    override func tableView(_ tableView: UITableView, willNeedPaginate cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == presenter.audioItems.count - 10 && presenter.isPageNeed {
            do {
                try presenter.onGetAudio(userId: userId, isPaginate: true)
            } catch {
                print(error)
                self.error(message: "Произошла ошибка")
            }
        }
    }
    
    override func getIndexPath(byItem item: AudioPlayerItem) -> IndexPath? {
        guard let row = presenter.audioItems.firstIndex(of: item) else { return nil }
        return IndexPath(row: row, section: 1)
    }
    
    @objc func openRecommendations(_ sender: UIBarButtonItem) {
        presenter.onOpenRecommendations()
    }
    
    @objc func changeIcon(_ sender: UIBarButtonItem) {
        UIApplication.shared.setAlternateIconName("AppIcon-1") { error in
            if let error = error {
                print(error.localizedDescription)
            } else {
                print("Success!")
            }
        }
    }
    
    @objc func openFriends(_ sender: UIBarButtonItem) {
        presenter.onOpenFriends()
    }
}

// MARK: - Extensions -

extension NLPAudioV2ViewController: NLPAudioV2ViewInterface {
    func didRemoveAudioInCache(audio: AudioPlayerItem) {
        guard let indexPath = getIndexPath(byItem: audio) else { return }
        
        DispatchQueue.main.async { [self] in
            presenter.audioItems.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .left)
        }
    }
}

extension NLPAudioV2ViewController: UITableViewDelegate, UITableViewDataSource, SkeletonTableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return presenter.dataSource?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 || section == 1 ? presenter.dataSource?[section].items.count ?? 0 : presenter.dataSource?[section].items[0].items.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0, 1:
            let item = presenter.dataSource?[indexPath.section].items[indexPath.row]

            guard let sectionItem = item, let cell = tableView.dequeueReusableCell(withIdentifier: .listCell(.folder), for: indexPath) as? NLPFolderViewCell else { return UITableViewCell() }
            cell.configure(with: sectionItem, isShuffle: indexPath.section == 1)
            
            cell.delegate = self
            
            return cell
        case 2:
            let item = presenter.dataSource?[indexPath.section].items[0]

            guard let audio = item?.items[indexPath.row], let cell = tableView.dequeueReusableCell(withIdentifier: .listCell(.audio), for: indexPath) as? NLPAudioViewCell else { return UITableViewCell() }
            cell.configure(with: audio)
            
            cell.delegate = self
            cell.menuDelegate = self
            
            cell.setDownloadProcess(audio.downloadStatus, indexPath: indexPath)
            
            return cell
        default:
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = NLPHeaderView()

        switch section {
        case 0, 2:
            return header
        case 1:
            let title: String = presenter.dataSource?[2].title ?? ""
            let count = presenter.dataSource?[2].count ?? 0
            let stringCount: String = count > 0 ? "\(count)" : ""
            header.attributedTitle = NSAttributedString(string: title, attributes: [.font: UIFont.systemFont(ofSize: 17, weight: .semibold), .foregroundColor: UIColor.label]) + attributedSpace + attributedSpace + NSAttributedString(string: stringCount, attributes: [.font: UIFont.systemFont(ofSize: 13, weight: .regular), .foregroundColor: UIColor.secondaryLabel])
            return header
        default:
            return nil
        }
        
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 0:
            return 1
        case 1:
            return 44
        case 2:
            return 0
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return section == 0 ? 12 : CGFloat.leastNormalMagnitude
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        indexPath.section == 0 ? 48 : 60
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func numSections(in collectionSkeletonView: UITableView) -> Int {
        return 3
    }
    
    func collectionSkeletonView(_ skeletonView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 3
        case 1:
            return 1
        case 2:
            return 25
        default:
            return 0
        }
    }
    
    func collectionSkeletonView(_ skeletonView: UITableView, cellIdentifierForRowAt indexPath: IndexPath) -> ReusableCellIdentifier {
        return indexPath.section == 0 || indexPath.section == 1 ? .listCell(.folder) : .listCell(.audio)
    }
    
    func collectionSkeletonView(_ skeletonView: UITableView, skeletonCellForRowAt indexPath: IndexPath) -> UITableViewCell? {
        if indexPath.section == 0 || indexPath.section == 1 {
            guard let cell = skeletonView.dequeueReusableCell(withIdentifier: .listCell(.folder), for: indexPath) as? NLPFolderViewCell else { return UITableViewCell() }
            return cell
        } else {
            guard let cell = skeletonView.dequeueReusableCell(withIdentifier: .listCell(.audio), for: indexPath) as? NLPAudioViewCell else { return UITableViewCell() }
            return cell
        }
    }
    
    func collectionSkeletonView(_ skeletonView: UITableView, prepareCellForSkeleton cell: UITableViewCell, at indexPath: IndexPath) {
        cell.isSkeletonable = true
    }
}
