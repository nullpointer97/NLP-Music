//
//  NLPAudioViewController.swift
//  NLPMusic
//
//  Created by Ярослав Стрельников on 04.04.2022.
//  Copyright (c) 2022 Extended Team. All rights reserved.
//

import UIKit
import MaterialComponents
import SkeletonView

final class NLPAudioViewController: NLPBaseTableViewController {

    // MARK: - Public properties -

    var presenter: NLPAudioPresenterInterface!
    var userId = currentUserId
    var name = ""

    // MARK: - Lifecycle -

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTable()

        do {
            try presenter.onGetAudio(userId: userId, isPaginate: false)
        } catch {
            print(error)
            self.error(message: .localized(.commonError))
        }

        if userId == currentUserId {
            navigationItem.leftBarButtonItems = [
                UIBarButtonItem(image: .init(named: "fire_outline_28")?.tint(with: .getAccentColor(fromType: .common).withAlphaComponent(0)), style: .done, target: self, action: #selector(changeIcon(_:))),
            ]
            navigationItem.rightBarButtonItems = [
                UIBarButtonItem(image: .init(named: "fire_outline_28")?.tint(with: .getAccentColor(fromType: .common)), style: .done, target: self, action: #selector(openRecommendations(_:))),
                UIBarButtonItem(image: .init(named: "users_outline_28")?.tint(with: .getAccentColor(fromType: .common)), style: .done, target: self, action: #selector(openFriends(_:)))
            ]
        } else {
            navigationItem.rightBarButtonItems = []
        }
        
        observables.append(UserDefaults.standard.observe(UInt32.self, key: "_accentColor") {
            _ = $0
            if self.userId == currentUserId {
                self.navigationItem.rightBarButtonItems = [
                    UIBarButtonItem(image: .init(named: "fire_outline_28")?.tint(with: .getAccentColor(fromType: .common)), style: .done, target: self, action: #selector(self.openRecommendations(_:))),
                    UIBarButtonItem(image: .init(named: "users_outline_28")?.tint(with: .getAccentColor(fromType: .common)), style: .done, target: self, action: #selector(self.openFriends(_:)))
                ]
            } else {
                self.navigationItem.rightBarButtonItems = []
            }
        })
    }
    
    override func didOpenMenu(audio cell: NLPBaseViewCell<AudioPlayerItem>) {
        super.didOpenMenu(audio: cell)

        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let item = audioItems[indexPath.row]
        
        let saveAction = MDCActionSheetAction(title: .localized(.save), image: UIImage(named: "download_outline_28")?.tint(with: .label)) { [weak self] _ in
            guard let self = self else { return }
            self.didSaveAudio(item, indexPath: indexPath)
        }
        saveAction.tintColor = .label
        saveAction.titleColor = .label
        saveAction.isEnabled = true
        
        let addAction = MDCActionSheetAction(title: .localized(.addToLibrary), image: UIImage(named: "add_outline_24")?.tint(with: .label)) { [weak self] _ in
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
        
        let removeAction = MDCActionSheetAction(title: .localized(.delete), image: UIImage(named: "delete_outline_28")?.tint(with: .systemRed)) { [weak self] _ in
            guard let self = self else { return }
            do {
                try self.presenter.onRemoveAudio(audio: item)
            } catch {
                self.showEventMessage(.error, message: .localized(.commonError))
            }
        }
        removeAction.tintColor = .systemRed
        removeAction.titleColor = .systemRed
        removeAction.isEnabled = true
        
        let removeInCacheAction = MDCActionSheetAction(title: .localized(.deleteFromCache), image: UIImage(named: "delete_outline_28")?.tint(with: .systemRed)) { [weak self] _ in
            guard let self = self else { return }
            self.didRemoveAudio(item, indexPath: indexPath)
        }
        removeInCacheAction.tintColor = .systemRed
        removeInCacheAction.titleColor = .systemRed
        removeInCacheAction.isEnabled = true
        
        if userId == currentUserId {
            openMenu(fromItem: item, actions: item.isDownloaded ? [removeAction, removeInCacheAction] : [saveAction, removeAction], title: item.title)
        } else {
            openMenu(fromItem: item, actions: item.isDownloaded ? [addAction, removeInCacheAction] : [addAction, saveAction], title: item.title)
        }
    }
    
    override func setupTable(style: UITableView.Style = .plain) {
        super.setupTable()
        dataSource?.isCurrentUser = userId == currentUserId
        
        addRefreshControl()
        
        tableView.showAnimatedSkeleton()
        tableView.startSkeletonAnimation()
    }
    
    override func reload() {
        super.reload()
        if userId == currentUserId {
            footer.loadingText = audioItems.isEmpty ? .localized(.noAudios) : getStringByDeclension(number: audioItems.count, arrayWords: Settings.language.contains("English") ? Localization.en.audioCount : Localization.ru.audioCount)
        } else {
            footer.loadingText = audioItems.isEmpty ? (.localized(.noAudiosPrefix) + name + .localized(.noAudiosSuffix)) : getStringByDeclension(number: audioItems.count, arrayWords: Settings.language.contains("English") ? Localization.en.audioCount : Localization.ru.audioCount)
        }
    }
    
    override func reloadAudioData() {
        do {
            try presenter.onGetAudio(userId: userId, isPaginate: false)
        } catch {
            print(error)
            self.error(message: .localized(.commonError))
        }
    }
    
    override func tableView(_ tableView: UITableView, willNeedPaginate cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == presenter.audioItems.count - 10 && presenter.isPageNeed {
            do {
                try presenter.onGetAudio(userId: userId, isPaginate: true)
            } catch {
                print(error)
                self.error(message: .localized(.commonError))
            }
        }
    }
    
    override func getIndexPath(byItem item: AudioPlayerItem) -> IndexPath? {
        guard let row = presenter.audioItems.firstIndex(of: item) else { return nil }
        return IndexPath(row: row, section: 1)
    }
    
    override func didAddAudio(_ item: AudioPlayerItem) {
        do {
            try self.presenter.onAddAudio(audio: item)
        } catch {
            self.showEventMessage(.error, message: error.localizedDescription)
        }
    }
    
    override func didRemoveAudio(_ item: AudioPlayerItem) {
        do {
            try self.presenter.onRemoveAudio(audio: item)
        } catch {
            self.showEventMessage(.error, message: .localized(.commonError))
        }
    }
    
    override func didRemoveFromCacheAudio(_ item: AudioPlayerItem) {
        didRemoveAudio(item, indexPath: getIndexPath(byItem: item) ?? IndexPath())
    }
    
    override func didSaveAudio(_ item: AudioPlayerItem) {
        didSaveAudio(item, indexPath: getIndexPath(byItem: item) ?? IndexPath())
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

extension NLPAudioViewController: NLPAudioViewInterface {
    func didRemoveAudioInCache(audio: AudioPlayerItem) {
        guard let indexPath = getIndexPath(byItem: audio) else { return }
        
        DispatchQueue.main.async { [self] in
            presenter.audioItems.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .left)
        }
    }
}
