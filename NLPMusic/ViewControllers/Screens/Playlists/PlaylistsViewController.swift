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
    var tableView: UITableView!
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
        
        setupTable()
        
        do {
            try getPlaylists()
        } catch {
            print(error)
        }
        
        observables.append(UserDefaults.standard.observe(UInt32.self, key: "_accentColor") {
            _ = $0
            self.reload()
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        reload()
        
        asdk_navigationViewController?.navigationBar.prefersLargeTitles = true
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        reload()
    }
    
    func setupTable() {
        tableView = UITableView(frame: view.frame, style: .plain)
        tableView.add(to: view)
        tableView.autoPinEdgesToSuperviewEdges()
        tableView.register(.listCell(.listPlaylist), forCellReuseIdentifier: .listCell(.listPlaylist))

        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(refreshPlaylists), for: .valueChanged)
        tableView.tableFooterView = footer

        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.separatorStyle = .none
        tableView.alwaysBounceVertical = true
    }
    
    
    
    @objc func reload() {
        tableView.reloadData()
    }
    
    @objc private func refreshPlaylists() {
        do {
            try getPlaylists()
        } catch {
            print(error)
        }
    }
}
