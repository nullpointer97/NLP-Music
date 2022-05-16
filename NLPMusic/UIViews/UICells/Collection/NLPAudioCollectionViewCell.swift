//
//  NLPAudioCollectionViewCell.swift
//  NLPMusic
//
//  Created by Ярослав Стрельников on 15.05.2022.
//  Copyright © 2022 NP-Team. All rights reserved.
//

import UIKit

class NLPAudioCollectionViewCell: NLPBaseCollectionViewCell<AudioPlayerItem> {
    @IBOutlet weak var artworkImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var moreButton: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        skeletonable(true)
        artworkImageView.drawBorder(4, width: 0.5, color: .adaptableBorder)
        titleLabel.textColor = .label
        artistLabel.textColor = .secondaryLabel
        
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: UIFont.Weight(0.25))
    }

    override func configure(with item: AudioPlayerItem) {
        artworkImageView.kf.setImage(with: item.albumThumb135?.toUrl())
        titleLabel.text = item.title
        artistLabel.text = item.artist
        
        skeletonable(false)
    }

    func skeletonable(_ state: Bool) {
        if state {
            moreButton.isHidden = true
            artworkImageView.showAnimatedGradientSkeleton()
            titleLabel.showAnimatedGradientSkeleton()
            artistLabel.showAnimatedGradientSkeleton()
        } else {
            moreButton.isHidden = false

            artworkImageView.hideSkeleton()
            titleLabel.hideSkeleton()
            artistLabel.hideSkeleton()
            
            artworkImageView.drawBorder(8, width: 0.5, color: .adaptableBorder)
            titleLabel.textColor = .label
            artistLabel.textColor = .secondaryLabel
        }
    }
}
