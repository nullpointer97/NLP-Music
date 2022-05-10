//
//  VKSavedMusicViewController.swift
//  vkmusic
//
//  Created by Ярослав Стрельников on 01.03.2022.
//  Copyright © 2022 NP-Team. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import CoreStore
import MaterialComponents

class NLPSavedMusicViewController: NLPBaseTableViewController {
    private var diffableDataSource: DiffableDataSource.TableViewAdapter<AudioItem>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        audioItems = AudioDataStackService.audios.snapshot.compactMap { AudioPlayerItem(from: $0.object!) }

        setupTable()

        NotificationCenter.default.addObserver(self, selector: #selector(didClearCache), name: NSNotification.Name("didCleanCache"), object: nil)
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(image: .init(named: "shuffle-2")?.tint(with: .getAccentColor(fromType: .common).withAlphaComponent(audioItems.count == 0 ? 0.5 : 1)), style: .done, target: self, action: #selector(didShuffleAll(_:))),
            UIBarButtonItem(image: .init(named: "play.fill")?.tint(with: .getAccentColor(fromType: .common).withAlphaComponent(audioItems.count == 0 ? 0.5 : 1)), style: .done, target: self, action: #selector(didPlayAll(_:)))
        ]
    }
    
    override func setupTable(style: UITableView.Style = .plain) {
        super.setupTable()
        tableView.delegate = self
        tableView.dataSource = nil
        tableView.refreshControl = nil
        
        diffableDataSource = EditableDataSource<AudioItem>(tableView: tableView, dataStack: AudioDataStackService.dataStack, cellProvider: { (tableView, indexPath, audio) in
            guard let cell = tableView.dequeueReusableCell(withIdentifier: .listCell(.audio), for: indexPath) as? NLPAudioViewCell else { return UITableViewCell() }
            cell.configure(withSavedItem: audio)
            
            cell.delegate = self
            cell.menuDelegate = self
            
            return cell
        })
        diffableDataSource?.apply(AudioDataStackService.audios.snapshot, animatingDifferences: true)
        AudioDataStackService.audios.addObserver(self) { [weak self] listPublisher in
            guard let self = self else { return }
            self.audioItems = listPublisher.snapshot.compactMap { AudioPlayerItem(from: $0.object!) }
            self.diffableDataSource?.apply(listPublisher.snapshot, animatingDifferences: true)
            
            self.navigationItem.rightBarButtonItems = [
                UIBarButtonItem(image: .init(named: "shuffle-2")?.tint(with: .getAccentColor(fromType: .common).withAlphaComponent(self.audioItems.count == 0 ? 0.5 : 1)), style: .done, target: self, action: #selector(self.didShuffleAll(_:))),
                UIBarButtonItem(image: .init(named: "play.fill")?.tint(with: .getAccentColor(fromType: .common).withAlphaComponent(self.audioItems.count == 0 ? 0.5 : 1)), style: .done, target: self, action: #selector(self.didPlayAll(_:)))
            ]
        }
    }
    
    override func didOpenMenu(audio cell: NLPBaseViewCell<AudioPlayerItem>) {
        super.didOpenMenu(audio: cell)
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        guard let item = AudioDataStackService.audios.snapshot[indexPath.row].object else { return }
        
        let removeInCacheAction = MDCActionSheetAction(title: "Удалить из кэша", image: UIImage(named: "delete_outline_28")?.tint(with: .systemRed)) { [weak self] _ in
            guard let self = self else { return }
            self.didRemoveAudio(AudioPlayerItem(from: item), indexPath: indexPath)
        }
        removeInCacheAction.tintColor = .systemRed
        removeInCacheAction.titleColor = .systemRed
        openMenu(fromItem: AudioPlayerItem(from: item), actions: [removeInCacheAction])
    }
    
    @objc func didClearCache() {
        audioItems = AudioDataStackService.audios.snapshot.compactMap { $0.object }.compactMap { AudioPlayerItem(from: $0) }
        tableView.reloadData()
    }
}

extension NLPSavedMusicViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        60
    }
}
