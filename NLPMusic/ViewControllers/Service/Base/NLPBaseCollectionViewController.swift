//
//  NLPBaseCollectionViewController.swift
//  NLPMusic
//
//  Created by Ярослав Стрельников on 15.05.2022.
//  Copyright © 2022 NP-Team. All rights reserved.
//

import Foundation
import UIKit

class NLPBaseCollectionViewController: NLPBaseViewController {
    var collectionView: UICollectionView!
    var pullToRefresh: DRPRefreshControl!

    var vkTabBarController: NLPTabController? {
        return tabBarController as? NLPTabController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func setupCollectionView(collectionViewLayout: UICollectionViewLayout) {
        collectionView = UICollectionView(frame: view.frame, collectionViewLayout: collectionViewLayout)
        collectionView.add(to: view)
        collectionView.autoPinEdgesToSuperviewEdges()
        
        pullToRefresh = DRPRefreshControl()
        pullToRefresh.add(to: collectionView, target: self, selector: #selector(reloadCollectionData))
        
        collectionView.register(.listCell(.playlist), forCellWithReuseIdentifier: .listCell(.playlist))
        collectionView.register(.listCell(.collectionAudio), forCellWithReuseIdentifier: .listCell(.collectionAudio))
        collectionView.register(.listCell(.collectionAlbum), forCellWithReuseIdentifier: .listCell(.collectionAlbum))
        collectionView.register(.listCell(.collectionLargeImage), forCellWithReuseIdentifier: .listCell(.collectionLargeImage))
        collectionView.register(.listCell(.collectionGroup), forCellWithReuseIdentifier: .listCell(.collectionGroup))
        collectionView.register(NLPCollectionHeaderCollectionReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "NLPCollectionHeaderCollectionReusableView")
    }
    
    @objc func reloadCollectionData() { }
}
