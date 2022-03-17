//
//  PlaylistsViewController.swift
//  vkmusic
//
//  Created by Ярослав Стрельников on 04.03.2022.
//  Copyright © 2022 NP-Team. All rights reserved.
//

import UIKit
import Alamofire
import ObjectMapper

class PlaylistsViewController: VKBaseViewController {
    var collectionView: UICollectionView!
    var footer: UITableViewFooter = UITableViewFooter(frame: .init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 40))
    
    var isPageNeed: Bool = true
    lazy var refreshControl = UIRefreshControl()
    
    var vkTabBarController: VKTabController? {
        return tabBarController as? VKTabController
    }
    
    var nextFrom: String = ""
    var playlistItems: [Playlist] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCollection()
        
        do {
            try getPlaylists()
        } catch {
            print(error)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    func setupCollection() {
        collectionView = UICollectionView(frame: view.frame, collectionViewLayout: UICollectionViewFlowLayout())
        collectionView.add(to: view)
        collectionView.autoPinEdgesToSuperviewEdges()
        collectionView.register(.listCell(.playlist), forCellWithReuseIdentifier: .listCell(.playlist))

        collectionView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(refreshPlaylists), for: .valueChanged)

        collectionView.delegate = self
        collectionView.dataSource = self
    }
    
    func getPlaylists(isPaginate: Bool = false) throws {
        var parametersAudio: Parameters = [
            "owner_id" : currentUserId,
            "count" : 20,
        ]
        
        if isPaginate {
            parametersAudio["start_from"] = nextFrom
        }
        
        try ApiV2.method("audio.getPlaylists", parameters: &parametersAudio, apiVersion: "5.90").done { result in
            self.refreshControl.beginRefreshing()
            self.nextFrom = result["response"]["next_from"].stringValue
            self.isPageNeed = result["response"]["count"].intValue > self.playlistItems.count
            guard let data = try? result.rawData() else { return }
            guard let items = Mapper<Response<PlaylistResponse>>().map(JSONString: data.string(encoding: .utf8) ?? "{ }")?.response.items else { return }
            
            self.playlistItems = items
        }.ensure {
            DispatchQueue.main.async { [self] in
                footer.isLoading = false
                refreshControl.endRefreshing()
                collectionView.reloadData()
            }
        }.catch { error in
            DispatchQueue.main.async { [self] in
                footer.loadingText = "Произошла ошибка при загрузке"
            }
            print(error)
        }
    }
    
    @objc private func refreshPlaylists() {
        do {
            try getPlaylists()
        } catch {
            print(error)
        }
    }
}

extension PlaylistsViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return playlistItems.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let playlist = playlistItems[indexPath.row]
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: .listCell(.playlist), for: indexPath) as? VKPlaylistCollectionViewCell else { fatalError() }
        
        cell.configure(with: playlist)
        return cell
    }
}

extension PlaylistsViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let playlist = playlistItems[indexPath.row]
        collectionView.deselectItem(at: indexPath, animated: true)
        
        let playlistController = PlaylistViewController(playlist)
        
        asdk_navigationViewController?.pushViewController(playlistController, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if indexPath.item == playlistItems.count - (UIDevice.current.userInterfaceIdiom == .pad ? 30 : 20) && isPageNeed {
            do {
                try getPlaylists(isPaginate: true)
            } catch {
                print(error)
            }
        }
    }
}

extension PlaylistsViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return UIDevice.current.userInterfaceIdiom == .pad ? .custom(collectionView.bounds.width / 4, (collectionView.bounds.width / 4) + 28) : .custom(collectionView.bounds.width / 3, (collectionView.bounds.width / 3) + 28)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .vertical(16)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}
