//
//  RecommendationsViewController.swift
//  NLPMusic
//
//  Created by Ярослав Стрельников on 17.03.2022.
//  Copyright © 2022 NP-Team. All rights reserved.
//

import UIKit
import Alamofire
import CoreStore
import MBProgressHUD
import MaterialComponents

class NLPRecommendationsViewController: NLPBaseTableViewController {
    var presenter: NLPRecommendationsPresenterInterface!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Рекомендации"
        
        setupTable()
        
        do {
            try presenter.onGetRecommendations()
        } catch {
            print(error)
        }
        
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
    
    override func setupTable(style: UITableView.Style = .plain) {
        super.setupTable()
        
        addRefreshControl()
        
        tableView.showAnimatedGradientSkeleton()
        tableView.startSkeletonAnimation()
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
        
        let removeInCacheAction = MDCActionSheetAction(title: "Удалить из кэша", image: UIImage(named: "delete_outline_28")?.tint(with: .systemRed)) { [weak self] _ in
            guard let self = self else { return }
            self.didRemoveAudio(item, indexPath: indexPath)
        }
        removeInCacheAction.tintColor = .systemRed
        removeInCacheAction.titleColor = .systemRed
        openMenu(fromItem: item, actions: item.isDownloaded ? [addAction, removeInCacheAction] : [addAction, saveAction])
    }
    
    override func reloadAudioData() {
        do {
            try presenter.onGetRecommendations()
        } catch {
            print(error)
        }
    }
}

extension NLPRecommendationsViewController: NLPRecommendationsViewInterface {
}
