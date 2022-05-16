//
//  NLPLargeImageViewCell.swift
//  NLPMusic
//
//  Created by Ярослав Стрельников on 16.05.2022.
//  Copyright © 2022 NP-Team. All rights reserved.
//

import UIKit

class NLPLargeImageViewCell: NLPBaseCollectionViewCell<Playlist> {
    @IBOutlet weak var artrorkImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var secondSubtitleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        skeletonable(true)
        artrorkImageView.drawBorder(8, width: 0.5, color: .adaptableBorder)
        titleLabel.textColor = .label
        subtitleLabel.textColor = .secondaryLabel
        secondSubtitleLabel.textColor = .secondaryLabel
        
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: UIFont.Weight(0.25))
    }
    
    override func configure(with item: Playlist) {
        artrorkImageView.kf.setImage(with: item.photo?.photo270?.toUrl())
        titleLabel.text = item.title
        subtitleLabel.text = item.mainArtists?.compactMap { $0.name }.joined(separator: ", ")
        
        let secondSubtitle = item.genres.compactMap { $0.name }.joined(separator: ", ") + "\(item.year ?? 0 > 0 ? " · \(item.year ?? 0)" : "")"
        secondSubtitleLabel.text = secondSubtitle
        
        skeletonable(false)
    }

    func skeletonable(_ state: Bool) {
        if state {
            artrorkImageView.showAnimatedGradientSkeleton()
            titleLabel.showAnimatedGradientSkeleton()
            subtitleLabel.showAnimatedGradientSkeleton()
            secondSubtitleLabel.showAnimatedGradientSkeleton()
        } else {
            artrorkImageView.hideSkeleton()
            titleLabel.hideSkeleton()
            subtitleLabel.hideSkeleton()
            secondSubtitleLabel.hideSkeleton()
            
            artrorkImageView.drawBorder(8, width: 0.5, color: .adaptableBorder)
            titleLabel.textColor = .label
            subtitleLabel.textColor = .secondaryLabel
            secondSubtitleLabel.textColor = .secondaryLabel
        }
    }
}
