//
//  NLPLargeAlbumViewCell.swift
//  NLPMusic
//
//  Created by Ярослав Стрельников on 16.05.2022.
//  Copyright © 2022 NP-Team. All rights reserved.
//

import UIKit

class NLPLargeAlbumViewCell: UICollectionViewCell {
    @IBOutlet weak var artworkImageView: UIImageView!
    @IBOutlet weak var titleView: UILabel!
    @IBOutlet weak var subtitleView: UILabel!
    @IBOutlet weak var subtitleSecondView: UILabel!
    @IBOutlet weak var moreButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        skeletonable()
    }
    
    func skeletonable() {
        artworkImageView.showAnimatedGradientSkeleton()
        titleView.showAnimatedGradientSkeleton()
        subtitleView.showAnimatedGradientSkeleton()
        subtitleSecondView.showAnimatedGradientSkeleton()
        moreButton.showAnimatedGradientSkeleton()
    }
}
