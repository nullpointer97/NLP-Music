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
            let cell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? VKPairButtonViewCell
            cell?.playButton.setTitleColor(.getAccentColor(fromType: .common), for: .normal)
            cell?.shuffleButton.setTitleColor(.getAccentColor(fromType: .common), for: .normal)
            
            cell?.playButton.setImage(.init(named: "play.fill")?.resize(toWidth: 20)?.resize(toHeight: 20)?.tint(with: .getAccentColor(fromType: .common)), for: .normal)
            cell?.shuffleButton.setImage(.init(named: "shuffle_24")?.resize(toWidth: 20)?.resize(toHeight: 20)?.tint(with: .getAccentColor(fromType: .common)), for: .normal)
            
            self.reload()
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        asdk_navigationViewController?.navigationBar.prefersLargeTitles = false
    }
    
    override func setupTable() {
        super.setupTable()
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    override func didOpenMenu(_ cell: VKBaseViewCell<AudioPlayerItem>) {
        super.didOpenMenu(cell)
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let item = audioItems[indexPath.row]
        
        openMenu(fromItem: item, actions: item.isDownloaded ? [
            .normal(id: 1, title: "Добавить к себе", completionHandler: { [weak self] _ in
                guard let self = self else { return }
                do {
                    try self.presenter.onAddAudio(audio: item)
                } catch {
                    self.showEventMessage(.error, message: "Произошла ошибка при добавлении")
                }
            })
        ] : [
            .normal(id: 0, title: "Сохранить", completionHandler: { [weak self] _ in
                guard let self = self else { return }
                self.didSaveAudio(item)
            }),
            .normal(id: 1, title: "Добавить к себе", completionHandler: { [weak self] _ in
                guard let self = self else { return }
                do {
                    try self.presenter.onAddAudio(audio: item)
                } catch {
                    self.showEventMessage(.error, message: "Произошла ошибка при добавлении")
                }
            })
        ])
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

extension NLPRecommendationsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        footer.loadingText = audioItems.isEmpty ? "У Вас нет аудиозаписей" : "Аудиозаписи загружены"
        return section == 0 ? 1 : audioItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: .listCell(.pairButton), for: indexPath) as? VKPairButtonViewCell else { return UITableViewCell() }
            cell.delegate = self
            return cell
        } else {
            let audio = audioItems[indexPath.row]
            guard let cell = tableView.dequeueReusableCell(withIdentifier: .listCell(.audio), for: indexPath) as? VKAudioViewCell else { return UITableViewCell() }
            cell.configure(with: audio)
            
            cell.delegate = self
            cell.menuDelegate = self
            
            return cell
        }
    }
}

extension NLPRecommendationsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        indexPath.section == 0 ? 64 : 60
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    }
}
