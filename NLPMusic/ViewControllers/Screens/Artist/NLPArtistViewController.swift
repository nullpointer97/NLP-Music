//
//  NLPArtistViewController.swift
//  NLPMusic
//
//  Created by Ярослав Стрельников on 15.05.2022.
//  Copyright © 2022 NP-Team. All rights reserved.
//

import UIKit
import Alamofire

struct ArtistSectionItem: Hashable {
    var playlistItem: Playlist?
    var audioItem: AudioPlayerItem?
    var group: Group?
    
    var header: ArtistHeader?
    
    var placeholderId: String = ""
}

struct ArtistHeader: Hashable {
    var name: String
    var imgUrl: String?
    var isBlurred: Bool
}

enum Section: Int, CaseIterable {
    case popular
    case lastRelease
    case releases
    case releaseFeat
    case groups
    
    static func section(from type: String) -> Section {
        switch type {
        case "popular": return .popular
        case "lastRelease": return .lastRelease
        case "releases": return .releases
        case "releaseFeat": return .releaseFeat
        case "groups": return .groups
        default: return .popular
        }
    }
    
    var title: String {
        switch self {
        case .popular:
            return "Популярное"
        case .lastRelease:
            return "Последний релиз"
        case .releases:
            return "Релизы"
        case .releaseFeat:
            return "Участие в релизах"
        case .groups:
            return "Официальные страницы"
        }
    }
    
    func columnCount(for width: CGFloat) -> Int {
        let wideMode = width > 800
        switch self {
        case .popular:
            return wideMode ? 2 : 3
        case .releases, .releaseFeat:
            return wideMode ? 10 : 2
        case .groups, .lastRelease:
            return 1
        }
    }
    
    func hightSection() -> CGFloat {
        switch self {
        case .popular:
            return 180
        case .lastRelease:
            return 84
        case .releases, .releaseFeat:
            return 209
        case .groups:
            return 60
        }
    }
}

class NLPArtistViewController: NLPBaseCollectionViewController {
    var dataSource: UICollectionViewDiffableDataSource<Section, ArtistSectionItem>! = nil
    var snapshot = NSDiffableDataSourceSnapshot<Section, ArtistSectionItem>()

    var artistId: String = ""
    
    init(artistId: String) {
        self.artistId = artistId
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setNeedsStatusBarAppearanceUpdate()

        setupCollectionView(collectionViewLayout: NLPArtistCollectionViewCompositionalLayout())
        
        do {
            try getArtist()
        } catch {
            print(error)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        asdk_navigationViewController?.isLight = true

        asdk_navigationViewController?.navigationBar.setBackgroundAlpha(0)
        asdk_navigationViewController?.navigationBar.titleTextAttributes?[.foregroundColor] = UIColor.label.withAlphaComponent(0)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        asdk_navigationViewController?.isLight = false

        asdk_navigationViewController?.navigationBar.setBackgroundAlpha(1)
        asdk_navigationViewController?.navigationBar.titleTextAttributes?[.foregroundColor] = UIColor.label.withAlphaComponent(1)
    }
    
    override func setupCollectionView(collectionViewLayout: UICollectionViewLayout) {
        super.setupCollectionView(collectionViewLayout: collectionViewLayout)
        
        collectionView.delegate = self
        collectionView.contentInset.top = -(72 + (UIDevice.current.hasNotch ? 44 : 20))
        prepareDataSource()
    }
    
    private func prepareDataSource() {
        let sections = Section.allCases

        dataSource = UICollectionViewDiffableDataSource<Section, ArtistSectionItem>(collectionView: collectionView) { collectionView, indexPath, identifier -> UICollectionViewCell? in
            
            switch sections[indexPath.section] {
            case .popular:
                guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: .listCell(.collectionAudio), for: indexPath) as? NLPAudioCollectionViewCell else { fatalError() }
                cell.drawBorder(8, width: 0)
                cell.delegate = self
                
                if let audioItem = identifier.audioItem {
                    cell.configure(with: audioItem)
                }

                return cell
            case .lastRelease:
                guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: .listCell(.collectionAlbum), for: indexPath) as? NLPLargeAlbumViewCell else { fatalError() }
                cell.drawBorder(8, width: 0)
                cell.delegate = self

                if let playlist = identifier.playlistItem {
                    cell.configure(with: playlist)
                }

                return cell
            case .releases:
                guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: .listCell(.collectionLargeImage), for: indexPath) as? NLPLargeImageViewCell else { fatalError() }
                cell.drawBorder(8, width: 0)
                cell.delegate = self

                if let playlist = identifier.playlistItem {
                    cell.configure(with: playlist)
                }

                return cell
            case .releaseFeat:
                guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: .listCell(.collectionLargeImage), for: indexPath) as? NLPLargeImageViewCell else { fatalError() }
                cell.drawBorder(8, width: 0)
                cell.delegate = self
                
                if let playlist = identifier.playlistItem {
                    cell.configure(with: playlist)
                }

                return cell
            case .groups:
                guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: .listCell(.collectionGroup), for: indexPath) as? NLPGroupViewCell else { fatalError() }
                cell.drawBorder(8, width: 0)
                cell.delegate = self

                if let group = identifier.group {
                    cell.configure(with: group)
                }

                return cell
            }
        }
        
        let items: [Int] = [23, 13, 2, 1]
        snapshot.appendSections(sections)

        sections.enumerated().forEach {
            switch $0.element {
            case .popular:
                for _ in 0...items[$0.offset] {
                    snapshot.appendItems([ArtistSectionItem(playlistItem: nil, audioItem: nil, placeholderId: String.random(10))], toSection: .popular)
                }
            case .lastRelease:
                snapshot.appendItems([ArtistSectionItem(playlistItem: nil, audioItem: nil, placeholderId: String.random(10))], toSection: .lastRelease)
            case .releases:
                for _ in 0...items[$0.offset] {
                    snapshot.appendItems([ArtistSectionItem(playlistItem: nil, audioItem: nil, placeholderId: String.random(10))], toSection: .releases)
                }
            case .releaseFeat:
                for _ in 0...items[$0.offset] {
                    snapshot.appendItems([ArtistSectionItem(playlistItem: nil, audioItem: nil, placeholderId: String.random(10))], toSection: .releaseFeat)
                }
            case .groups:
                snapshot.appendItems([], toSection: .groups)
            }
        }
        
        dataSource.supplementaryViewProvider = { collectionView, identifier, indexPath -> UICollectionReusableView? in
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "NLPCollectionHeaderCollectionReusableView", for: indexPath) as? NLPCollectionHeaderCollectionReusableView
            let section = self.dataSource.snapshot().sectionIdentifiers[indexPath.section]
            let item = self.snapshot.itemIdentifiers(inSection: section)[indexPath.item]

            header?.isNeedBlur = item.header?.isBlurred ?? false
            header?.artistName = item.header?.name
            header?.imageUrl = section == .popular ? item.header?.imgUrl : nil
            header?.isNeedImage = section == .popular
            header?.title = section.title
            header?.isNeedSeparator = indexPath.section > 0
            header?.isNeedShowAll = section != .groups && section != .lastRelease
            
            return header
        }
        
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    private func getArtist() throws {
        if let path = Bundle.main.path(forResource: "ProfileGetter", ofType: "txt") {
            let code = try String(contentsOfFile: path, encoding: .utf8).replacingOccurrences(of: "insert_artist_id", with: artistId)
            
            var parameters: Parameters = ["code": code]
            
            try ApiV2.method("execute", parameters: &parameters).done { response in
                let items = response["response"]["items"].arrayValue
                let header = response["response"]["artist_info"]
                let sections = items.filter { $0["items"].arrayValue.count > 0 }.compactMap { Section.section(from: $0["type"].stringValue) }
                
                DispatchQueue.main.async {
                    self.snapshot.deleteSections([.popular, .lastRelease, .releaseFeat, .releases, .groups])
                    self.snapshot.deleteAllItems()
                    self.snapshot.appendSections(sections)
                    
                    sections.enumerated().forEach { index, section in
                        switch section {
                        case .popular:
                            self.snapshot.appendItems(items[index]["items"].arrayValue.compactMap { ArtistSectionItem(audioItem: AudioPlayerItem(fromJSON: $0), header: ArtistHeader(name: header["name"].stringValue, imgUrl: header["photo"].arrayValue.filter { $0["width"].intValue > 600 }.first?["url"].stringValue, isBlurred: header["is_album_cover"].boolValue)) }, toSection: .popular)
                        case .lastRelease:
                            self.snapshot.appendItems(items[index]["items"].arrayValue.compactMap { ArtistSectionItem(playlistItem: Playlist(JSON: $0.dictionaryObject ?? [:])) }, toSection: .lastRelease)
                        case .releases:
                            self.snapshot.appendItems(items[index]["items"].arrayValue.compactMap { ArtistSectionItem(playlistItem: Playlist(JSON: $0.dictionaryObject ?? [:])) }, toSection: .releases)
                        case .releaseFeat:
                            self.snapshot.appendItems(items[index]["items"].arrayValue.compactMap { ArtistSectionItem(playlistItem: Playlist(JSON: $0.dictionaryObject ?? [:])) }, toSection: .releaseFeat)
                        case .groups:
                            self.snapshot.appendItems(items[index]["items"].arrayValue.compactMap { ArtistSectionItem(group: Group().parse(from: $0)) }, toSection: .groups)
                        }
                    }
                    
                    if #available(iOS 15.0, *) {
                        self.dataSource.applySnapshotUsingReloadData(self.snapshot)
                    } else {
                        self.dataSource.apply(self.snapshot)
                        self.collectionView.reloadData()
                    }
                }
                
            }.catch { err in
                print(err)
            }
        }
    }
}

extension NLPArtistViewController: UICollectionViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let height: CGFloat = 140 - (UIDevice.current.hasNotch ? 44 : 20)
        
        var progress = scrollView.contentOffset.y / height
        progress = min(progress, 1)
        
        UIView.animate(withDuration: 0.05, delay: 0, options: [.allowUserInteraction, .beginFromCurrentState]) { [weak self] in
            var newProgress: CGFloat = 0
            
            if progress < 0 {
                newProgress = 0
            } else if progress > 1 {
                newProgress = 1
            } else {
                newProgress = progress
            }

            self?.asdk_navigationViewController?.navigationBar.titleTextAttributes?[.foregroundColor] = UIColor.label.withAlphaComponent(newProgress < 0.15 ? newProgress - 0.130 : newProgress)
            self?.asdk_navigationViewController?.navigationBar.backgroundView?.alpha = newProgress
            self?.asdk_navigationViewController?.navigationBar.tintColor = newProgress > 0.5 ? .getAccentColor(fromType: .common) : .white
            
            self?.asdk_navigationViewController?.isLight = newProgress < 0.5
        }
    }
}

extension NLPArtistViewController: NLPCollectionBaseItemDelegate {
    func didTap<T>(_ cell: NLPBaseCollectionViewCell<T>) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [self] in
            guard let indexPath = collectionView.indexPath(for: cell), let player = AudioService.instance.player else { return }
            let audioItems = snapshot.itemIdentifiers(inSection: .popular).compactMap({ item in
                return item.audioItem
            })
            let selectedItem = audioItems[indexPath.item]
            
            switch player.state {
            case .buffering, .playing:
                if player.currentItem?.id == selectedItem.id {
                    vkTabBarController?.openPopup(animated: true)
                } else {
                    player.play(items: audioItems, startAtIndex: indexPath.item)
                }
            case .paused:
                if player.currentItem?.id == selectedItem.id {
                    player.resume()
                } else {
                    player.play(items: audioItems, startAtIndex: indexPath.item)
                }
            case .stopped:
                player.play(items: audioItems, startAtIndex: indexPath.item)
            case .waitingForConnection:
                log("player wait connection", type: .warning)
            case .failed(let error):
                log(error.localizedDescription, type: .error)
            }
        }
    }
    
    func perform<T>(from cell: NLPBaseCollectionViewCell<T>) {
        guard let indexPath = collectionView.indexPath(for: cell) else { return }
        let section = snapshot.sectionIdentifiers[indexPath.section]
        let item = snapshot.itemIdentifiers(inSection: section)[indexPath.item]

        switch section {
        case .popular:
            break
        case .lastRelease, .releases, .releaseFeat:
            if let playlist = item.playlistItem {
                asdk_navigationViewController?.pushViewController(NLPPlaylistWireframe(playlist).viewController, animated: true)
            }
        case .groups:
            let url = URL(string: "vk://\((item.group?.url ?? "").replacingOccurrences(of: "https://", with: ""))")
            if UIApplication.shared.canOpenURL(url!) {
                UIApplication.shared.open(url!)
            } else {
                showEventMessage(.error, message: "Телеграм не установлен")
            }
        }
    }
    
    func logout<T>(from cell: NLPBaseCollectionViewCell<T>) {
        
    }
}

class NLPArtistCollectionViewCompositionalLayout: UICollectionViewCompositionalLayout {
    var headerReferenceSize = CGSize.custom(0, 250)
    
    init(with sections: [Section] = []) {
        super.init { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
            guard let sectionKind = Section(rawValue: sectionIndex) else { return nil }
            let columns = sectionKind.columnCount(for: layoutEnvironment.container.effectiveContentSize.width)
            let width = layoutEnvironment.container.effectiveContentSize.width
            
            let popularItemSize = NSCollectionLayoutSize(widthDimension: .absolute(width), heightDimension: .absolute(60))
            let popularItem = NSCollectionLayoutItem(layoutSize: popularItemSize)
            popularItem.contentInsets = .init(top: 0, leading: 0, bottom: 0, trailing: 8)
            
            let popularGroupHeight = NSCollectionLayoutDimension.absolute(sectionKind.hightSection())
            
            let popularGroupSize = NSCollectionLayoutSize(widthDimension: .absolute(width), heightDimension: popularGroupHeight)
            let popularGroup = NSCollectionLayoutGroup.vertical(layoutSize: popularGroupSize, subitem: popularItem, count: columns)
            popularGroup.interItemSpacing = .fixed(0)
            
            let lastReleaseItemSize = NSCollectionLayoutSize(widthDimension: .absolute(width), heightDimension: .absolute(84))
            let lastReleaseItem = NSCollectionLayoutItem(layoutSize: lastReleaseItemSize)
            lastReleaseItem.contentInsets = .init(top: 0, leading: 0, bottom: 0, trailing: 8)
            
            let lastReleaseGroupHeight = NSCollectionLayoutDimension.absolute(sectionKind.hightSection())
            
            let lastReleaseGroupSize = NSCollectionLayoutSize(widthDimension: .absolute(width), heightDimension: lastReleaseGroupHeight)
            let lastReleaseGroup = NSCollectionLayoutGroup.horizontal(layoutSize: lastReleaseGroupSize, subitem: lastReleaseItem, count: 1)
            
            let releaseItemSize = NSCollectionLayoutSize(widthDimension: .absolute(147), heightDimension: .absolute(209))
            let releaseItem = NSCollectionLayoutItem(layoutSize: releaseItemSize)
            releaseItem.contentInsets = .init(top: 0, leading: 0, bottom: 0, trailing: 0)
            
            let releaseGroupHeight = NSCollectionLayoutDimension.absolute(sectionKind.hightSection())
            
            let releaseGroupSize = NSCollectionLayoutSize(widthDimension: .absolute(147), heightDimension: releaseGroupHeight)
            let releaseGroup = NSCollectionLayoutGroup.horizontal(layoutSize: releaseGroupSize, subitems: [releaseItem])
            
            let releaseFeatItem = NSCollectionLayoutItem(layoutSize: releaseItemSize)
            releaseFeatItem.contentInsets = .init(top: 0, leading: 0, bottom: 0, trailing: 0)
            
            let releaseFeatGroupHeight = NSCollectionLayoutDimension.absolute(sectionKind.hightSection())
            
            let releaseFeatGroupSize = NSCollectionLayoutSize(widthDimension: .absolute(147), heightDimension: releaseFeatGroupHeight)
            let releaseFeatGroup = NSCollectionLayoutGroup.horizontal(layoutSize: releaseFeatGroupSize, subitems: [releaseFeatItem])
            
            let groupItemSize = NSCollectionLayoutSize(widthDimension: .absolute(width - 32), heightDimension: .absolute(60))
            let groupItem = NSCollectionLayoutItem(layoutSize: groupItemSize)
            groupItem.contentInsets = .init(top: 2, leading: 2, bottom: 2, trailing: 2)
            
            let groupGroupHeight = NSCollectionLayoutDimension.absolute(sectionKind.hightSection())
            
            let groupGroupSize = NSCollectionLayoutSize(widthDimension: .absolute(width - 32), heightDimension: groupGroupHeight)
            let groupGroup = NSCollectionLayoutGroup.vertical(layoutSize: groupGroupSize, subitem: groupItem, count: columns)
            
            let section: NSCollectionLayoutSection
            
            switch sectionKind {
            case .popular:
                section = NSCollectionLayoutSection(group: popularGroup)
                section.orthogonalScrollingBehavior = .paging
                section.contentInsets = .init(top: 0, leading: 16, bottom: 12, trailing: 16)
            case .lastRelease:
                section = NSCollectionLayoutSection(group: lastReleaseGroup)
                section.contentInsets = .init(top: 0, leading: 16, bottom: 12, trailing: 16)
            case .releases:
                section = NSCollectionLayoutSection(group: releaseGroup)
                section.orthogonalScrollingBehavior = .continuousGroupLeadingBoundary
                section.contentInsets = .init(top: 4, leading: 16, bottom: 6, trailing: 16)
            case .releaseFeat:
                section = NSCollectionLayoutSection(group: releaseFeatGroup)
                section.orthogonalScrollingBehavior = .continuousGroupLeadingBoundary
                section.contentInsets = .init(top: 4, leading: 16, bottom: 6, trailing: 16)
            case .groups:
                section = NSCollectionLayoutSection(group: groupGroup)
                section.orthogonalScrollingBehavior = .none
                section.contentInsets = .init(top: 4, leading: 16, bottom: 16, trailing: 16)
            }
            
            section.boundarySupplementaryItems = [NLPArtistCollectionViewCompositionalLayout.makeHeader(section: sectionKind)]
            
            return section
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let attributesArray = super.layoutAttributesForElements(in: rect)

        guard let collectionView = self.collectionView else { return attributesArray }
        let offset = collectionView.contentOffset
        let minY: CGFloat = 13
        
        
        if offset.y < minY {
            let headerSize = self.headerReferenceSize
            let deltaY = CGFloat(fabsf(Float(offset.y - minY)))
            
            
            for attr: UICollectionViewLayoutAttributes in attributesArray! {
                if attr.representedElementKind == UICollectionView.elementKindSectionHeader && attr.indexPath.section == 0 {
                    var headerRect = attr.frame
                    headerRect.size.height = max(minY, headerSize.height + deltaY)
                    headerRect.origin.y = -(headerRect.size.height - headerSize.height)

                    attr.frame = headerRect
                    break
                }
            }
        }
        
        return attributesArray
    }
    
    private static func makeHeader(section: Section) -> NSCollectionLayoutBoundarySupplementaryItem {
        switch section {
        case .popular:
            let size = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(250))
            let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: size, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
            return header
        default:
            let size = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(40))
            let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: size, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
            return header
        }
    }
}
