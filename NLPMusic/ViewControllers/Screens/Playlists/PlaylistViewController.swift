//
//  PlaylistViewController.swift
//  vkmusic
//
//  Created by Ярослав Стрельников on 04.03.2022.
//  Copyright © 2022 NP-Team. All rights reserved.
//

import UIKit
import Kingfisher
import Alamofire
import CoreStore

class PlaylistViewController: VKBaseTableViewController {
    let playlist: Playlist
    
    var headerView: StickyHeaderView!
    
    init(_ playlist: Playlist) {
        self.playlist = playlist
        super.init(nibName: nil, bundle: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        downloadService.session = session
        
        asdk_navigationViewController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.label.withAlphaComponent(0)]
        navigationItem.title = playlist.title
        
        setupTable()
        
        do {
            try getPlaylistAudio()
        } catch {
            print(error)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(updatePlayingItem(_:)), name: NSNotification.Name("WillResumePlaying"), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationItem.largeTitleDisplayMode = .never
    }
    
    override func setupTable() {
        super.setupTable()
        let year = playlist.year ?? 0
        let artist = playlist.mainArtists?.first?.name ?? ""

        headerView = StickyHeaderView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: StickyHeaderView.getHeight(isArtistAvailable: !artist.isEmpty, isYearAvailable: year > 0)))
        
        tableView.delegate = self
        tableView.dataSource = self

        footer.isLoading = true
        
        if let imageUrl = URL(string: playlist.photo?.photo300) {
            headerView.imageView.imageView.kf.setImage(with: imageUrl)
        } else {
            headerView.imageView.imageView.image = .init(named: "playlist_outline_56")
        }
        
        headerView.titleLabel.text = playlist.title
        headerView.subtitleLabel.text = playlist.mainArtists?.first?.name
        
        headerView.subtitleSecondLabel.text = playlist.year?.stringValue
    }
}

extension PlaylistViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let headerView = tableView.tableHeaderView as? StickyHeaderView else { return }
        headerView.scrollViewDidScroll(scrollView)

        let height = headerView.bounds.height
        let maxOffset = height + 64
        
        var progress = (scrollView.contentOffset.y + (UIDevice.current.hasNotch ? 64 : 84) + 90) / maxOffset
        progress = min(progress, 1)
        
        print(progress)
        
        if progress <= 1 && progress >= 0 {
            let newProgress = progress < 0.5 ? progress - 0.2 : progress
            UIView.animate(withDuration: 0.05, delay: 0, options: [.allowUserInteraction, .beginFromCurrentState]) { [weak self] in
                self?.asdk_navigationViewController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.label.withAlphaComponent(newProgress)]
                headerView.imageView.alpha = 1 - newProgress
                headerView.titleLabel.alpha = 1 - newProgress
                headerView.subtitleLabel.alpha = 1 - newProgress
                headerView.subtitleSecondLabel.alpha = 1 - newProgress
            }
        }
    }
}

extension PlaylistViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return audioItems.count > 0 ? 2 : 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let noEmptyText = playlist.plays > 0 ? getStringByDeclension(number: playlist.plays, arrayWords: Localization.plays) : getStringByDeclension(number: playlist.count, arrayWords: Localization.audioCount)
        footer.loadingText = audioItems.isEmpty ? "Плейлист пустой" : noEmptyText
        return audioItems.count > 0 ? section == 0 ? 1 : audioItems.count : 0
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

extension PlaylistViewController: MenuDelegate {
    func didOpenMenu(_ cell: VKBaseViewCell<AudioPlayerItem>) {
        
    }
}

extension PlaylistViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        indexPath.section == 0 ? 64 : 60
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == audioItems.count - 5 && presenter.isPageNeed {
            do {
                try getPlaylistAudio(isPaginate: true)
            } catch {
                print(error)
            }
        }
    }
}
