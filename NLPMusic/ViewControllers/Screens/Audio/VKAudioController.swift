//
//  VKAudioController.swift
//  vkmusic
//
//  Created by Ярослав Стрельников on 02.02.2022.
//  Copyright © 2022 NP-Team. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import CoreStore
import ObjectMapper
import AsyncDisplayKit
import MBProgressHUD

class VKAudioController: NLPBaseTableViewController {
    var isPageNeed: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupTable()
        
        do {
            try getAudio()
        } catch {
            print(error)
        }

        NotificationCenter.default.addObserver(self, selector: #selector(didClearCache), name: NSNotification.Name("didCleanCache"), object: nil)
    
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Рекомендации", style: .plain, target: self, action: #selector(openRecommendations(_:)))
        
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
    
    override func setupTable() {
        super.setupTable()
        tableView.delegate = self
        tableView.dataSource = self
        footer.isLoading = true
    }
    
    override func didOpenMenu(_ cell: NLPBaseViewCell<AudioPlayerItem>) {
        super.didOpenMenu(cell)
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let item = audioItems[indexPath.row]
        
        openMenu(fromItem: item, actions: item.isDownloaded ? [
            .normal(id: 1, title: "Удалить", completionHandler: { [weak self] _ in
                guard let self = self else { return }
                do {
                    try self.removeAudio(audio: item)
                } catch {
                    self.showEventMessage(.error, message: "Произошла ошибка при удалении")
                }
            })
        ] : [
            .normal(id: 0, title: "Сохранить", completionHandler: { [weak self] _ in
                guard let self = self else { return }
                self.didSaveAudio(item)
            }),
            .normal(id: 1, title: "Удалить", completionHandler: { [weak self] _ in
                guard let self = self else { return }
                do {
                    try self.removeAudio(audio: item)
                } catch {
                    self.showEventMessage(.error, message: "Произошла ошибка при удалении")
                }
            })
        ])
    }

    @objc func didClearCache() {
        reload()
    }
    
    func getAudio(isPaginate: Bool = false) throws {
        var parametersAudio: Parameters = [
            "user_id" : currentUserId,
            "count" : 30,
            "offset": isPaginate ? self.audioItems.count : 0
        ]
        
        try ApiV2.method(.getAudio, parameters: &parametersAudio, apiVersion: .defaultApiVersion).done { result in
            self.isPageNeed = result["response"]["count"].intValue > self.audioItems.count

            let items = result["response"]["items"].arrayValue
            
            if isPaginate {
                self.audioItems.append(contentsOf: items.compactMap { AudioPlayerItem(fromJSON: $0) }.uniqued())
            } else {
                self.audioItems.removeAll()
                self.audioItems.insert(contentsOf: items.compactMap { AudioPlayerItem(fromJSON: $0) }.uniqued(), at: 0)
            }
            
            self.vkTabBarController?.playerViewController.queueItems = self.audioItems
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
    
    func removeAudio(audio: AudioPlayerItem) throws {
        var parametersAudio: Parameters = [
            "audio_id" : audio.id,
            "owner_id" : audio.ownerId
        ]
        
        try ApiV2.method(.deleteAudio, parameters: &parametersAudio, apiVersion: .defaultApiVersion).done { result in
            guard result["response"].intValue == 1 else { return }
            guard let indexPath = self.getIndexPath(byItem: audio) else { return }
            
            DispatchQueue.main.async { [self] in
                audioItems.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .left)
            }
        }.catch { error in
            DispatchQueue.main.async { [self] in
                footer.loadingText = "Произошла ошибка при удалении"
            }
        }
    }
    
    @objc private func refreshAudio() {
        do {
            try getAudio()
        } catch {
            print(error)
        }
    }
    
    @objc func openRecommendations(_ sender: UIBarButtonItem) {
        let controller = NLPRecommendationsWireframe().viewController
        asdk_navigationViewController?.pushViewController(controller, animated: true)
    }
}

extension VKAudioController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return audioItems.count > 0 ? 2 : 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        footer.loadingText = audioItems.isEmpty ? "У Вас нет аудиозаписей" : "Аудиозаписи загружены"
        return audioItems.count > 0 ? section == 0 ? 1 : audioItems.count : 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: .listCell(.pairButton), for: indexPath) as? NLPPairButtonViewCell else { return UITableViewCell() }
            cell.delegate = self
            return cell
        } else {
            let audio = audioItems[indexPath.row]
            guard let cell = tableView.dequeueReusableCell(withIdentifier: .listCell(.audio), for: indexPath) as? NLPAudioViewCell else { return UITableViewCell() }
            cell.configure(with: audio)
            
            cell.delegate = self
            cell.menuDelegate = self
            
            return cell
        }
    }
}

extension VKAudioController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        indexPath.section == 0 ? 64 : 60
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == audioItems.count - 5 && isPageNeed {
            do {
                try getAudio(isPaginate: true)
            } catch {
                print(error)
            }
        }
    }
}
