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
    
    var placeholderId: String = ""
}

enum Section: Int, CaseIterable {
    case popular
    case releases
    case releaseFeat
    case groups
    
    static func section(from type: String) -> Section {
        switch type {
        case "popular": return .popular
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
        case .groups:
            return 1
        }
    }
    
    func hightSection() -> CGFloat {
        switch self {
        case .popular:
            return 180
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

        setupCollectionView(collectionViewLayout: createLayout())
        
        do {
            try getArtist()
        } catch {
            print(error)
        }
    }
    
    override func setupCollectionView(collectionViewLayout: UICollectionViewLayout) {
        super.setupCollectionView(collectionViewLayout: collectionViewLayout)
        
        prepareDataSource()
    }
    
    private func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
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
                section.contentInsets = .init(top: 4, leading: 16, bottom: 6, trailing: 16)
            }
            section.boundarySupplementaryItems = [self.makeHeader()]
            return section
        }
        return layout
    }
    
    private func makeHeader() -> NSCollectionLayoutBoundarySupplementaryItem {
        let size = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(40))
        let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: size, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
        return header
    }
    
    private func prepareDataSource() {
        let sections = Section.allCases

        dataSource = UICollectionViewDiffableDataSource<Section, ArtistSectionItem>(collectionView: collectionView) { collectionView, indexPath, identifier -> UICollectionViewCell? in
            
            switch sections[indexPath.section] {
            case .popular:
                guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: .listCell(.collectionAudio), for: indexPath) as? NLPAudioCollectionViewCell else { fatalError() }
                cell.drawBorder(8, width: 0)
                
                if let audioItem = identifier.audioItem {
                    cell.configure(with: audioItem)
                }

                return cell
            case .releases:
                guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: .listCell(.collectionLargeImage), for: indexPath) as? NLPLargeImageViewCell else { fatalError() }
                cell.drawBorder(8, width: 0)

                if let playlist = identifier.playlistItem {
                    cell.configure(with: playlist)
                }

                return cell
            case .releaseFeat:
                guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: .listCell(.collectionLargeImage), for: indexPath) as? NLPLargeImageViewCell else { fatalError() }
                cell.drawBorder(8, width: 0)
                
                if let playlist = identifier.playlistItem {
                    cell.configure(with: playlist)
                }

                return cell
            case .groups:
                guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: .listCell(.collectionGroup), for: indexPath) as? NLPGroupViewCell else { fatalError() }
                cell.drawBorder(8, width: 0)
                
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
                    self.snapshot.appendItems([ArtistSectionItem(playlistItem: nil, audioItem: nil, placeholderId: String.random(10))], toSection: .popular)
                }
            case .releases:
                for _ in 0...items[$0.offset] {
                    self.snapshot.appendItems([ArtistSectionItem(playlistItem: nil, audioItem: nil, placeholderId: String.random(10))], toSection: .releases)
                }
            case .releaseFeat:
                for _ in 0...items[$0.offset] {
                    self.snapshot.appendItems([ArtistSectionItem(playlistItem: nil, audioItem: nil, placeholderId: String.random(10))], toSection: .releaseFeat)
                }
            case .groups:
                self.snapshot.appendItems([], toSection: .groups)
            }
        }
        
        dataSource.supplementaryViewProvider = { collectionView, identifier, indexPath -> UICollectionReusableView? in
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "NLPCollectionHeaderCollectionReusableView", for: indexPath) as? NLPCollectionHeaderCollectionReusableView
            header?.title = sections[indexPath.section].title
            header?.isNeedShowAll = sections[indexPath.section] != .groups
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
                let sections = items.filter { $0["items"].arrayValue.count > 0 }.compactMap { Section.section(from: $0["type"].stringValue) }
                
                DispatchQueue.main.async {
                    self.snapshot.deleteSections([.popular, .releaseFeat, .releases, .groups])
                    self.snapshot.deleteAllItems()
                    self.snapshot.appendSections(sections)
                    
                    sections.enumerated().forEach { index, section in
                        switch section {
                        case .popular:
                            self.snapshot.appendItems(items[index]["items"].arrayValue.compactMap { ArtistSectionItem(audioItem: AudioPlayerItem(fromJSON: $0)) }, toSection: .popular)
                        case .releases:
                            self.snapshot.appendItems(items[index]["items"].arrayValue.compactMap { ArtistSectionItem(playlistItem: Playlist(JSON: $0.dictionaryObject ?? [:])) }, toSection: .releases)
                        case .releaseFeat:
                            self.snapshot.appendItems(items[index]["items"].arrayValue.compactMap { ArtistSectionItem(playlistItem: Playlist(JSON: $0.dictionaryObject ?? [:])) }, toSection: .releaseFeat)
                        case .groups:
                            self.snapshot.appendItems(items[index]["items"].arrayValue.compactMap { ArtistSectionItem(group: Group().parse(from: $0)) }, toSection: .groups)
                        }
                    }
                    
                    self.dataSource.apply(self.snapshot, animatingDifferences: false)
                }
                
            }.catch { err in
                print(err)
            }
        }
    }
}
