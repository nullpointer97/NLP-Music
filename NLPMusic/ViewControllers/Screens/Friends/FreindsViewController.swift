//
//  FreindsViewController.swift
//  NLPMusic
//
//  Created by Ярослав Стрельников on 21.04.2022.
//  Copyright © 2022 NP-Team. All rights reserved.
//

import Foundation
import UIKit
import Alamofire
import SkeletonView

class NLPFriendsViewController: NLPBaseTableViewController {
    var friends: [NLPUser] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = .localized(.friendsMusicTitle)

        setupTable()
        getFriends()
    }
    
    override func setupTable(style: UITableView.Style = .plain) {
        super.setupTable()

        tableView.dataSource = self
        tableView.delegate = self

        addRefreshControl()

        tableView.showAnimatedGradientSkeleton()
        tableView.startSkeletonAnimation()
    }
    
    func getFriends() {
        var parameters: Parameters = [
            "order": "hints",
            "fields": Constants.userFields
        ]
        
        do {
            try ApiV2.method(.getFriends, parameters: &parameters).done { friends in
                self.friends = friends["response"]["items"].arrayValue.filter{ $0["can_see_audio"].boolValue }.compactMap { NLPUser($0) }
                self.reload()
            }.ensure {
                DispatchQueue.main.async {
                    self.didFinishLoad()
                }
            }.catch { error in
                self.showEventMessage(.error, message: error.localizedDescription)
            }
        } catch {
            showEventMessage(.error, message: error.localizedDescription)
        }
    }
    
    override func reload() {
        super.reload()
    }
    
    override func didFinishLoad() {
        super.didFinishLoad()
        footer.loadingText = friends.isEmpty ? "У Вас нет друзей" : getStringByDeclension(number: friends.count, arrayWords: Settings.language.contains("English") ? Localization.en.friendsCount : Localization.ru.friendsCount)
    }
    
    override func reloadAudioData() {
        getFriends()
    }
}

extension NLPFriendsViewController: UITableViewDelegate, SkeletonTableViewDataSource {
    func collectionSkeletonView(_ skeletonView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 25
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        friends.count
    }
    
    func collectionSkeletonView(_ skeletonView: UITableView, cellIdentifierForRowAt indexPath: IndexPath) -> ReusableCellIdentifier {
        return .listCell(.smallUser)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: .listCell(.smallUser), for: indexPath) as? NLPUserViewCell else { return UITableViewCell() }
        guard friends.indices.contains(indexPath.row) else { return cell }
        let friend = friends[indexPath.row]
        cell.configure(with: friend)
        return cell
    }
    
    func collectionSkeletonView(_ skeletonView: UITableView, skeletonCellForRowAt indexPath: IndexPath) -> UITableViewCell? {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: .listCell(.smallUser), for: indexPath) as? NLPUserViewCell else { return UITableViewCell() }
        return cell
    }
    
    func collectionSkeletonView(_ skeletonView: UITableView, prepareCellForSkeleton cell: UITableViewCell, at indexPath: IndexPath) {
        let cell = cell as? NLPUserViewCell
        cell?.isSkeletonable = true
        cell?.contentView.isSkeletonable = true
        cell?.nameLabel.linesCornerRadius = 4
        for subview in cell?.contentView.subviews ?? [] {
            subview.isSkeletonable = true
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        44
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let friend = friends[indexPath.row]
        
        let audioController = NLPAudioWireframe().viewController
        audioController.userId = friend.id
        audioController.name = friend.firstNameGen
        audioController.title = Settings.language.contains("English") ? "\(friend.firstNameGen)'s music" : "\(String.localized(.musicTitle)) \(friend.firstNameGen)"
        
        asdk_navigationViewController?.pushViewController(audioController, animated: true)
    }
}
