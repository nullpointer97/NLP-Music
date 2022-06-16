//
//  NLPLargeAlbumViewCell.swift
//  NLPMusic
//
//  Created by Ярослав Стрельников on 16.05.2022.
//  Copyright © 2022 NP-Team. All rights reserved.
//

import UIKit

class NLPLargeAlbumViewCell: NLPBaseCollectionViewCell<Playlist> {
    @IBOutlet weak var artworkImageView: UIImageView!
    @IBOutlet weak var titleView: UILabel!
    @IBOutlet weak var subtitleView: UILabel!
    @IBOutlet weak var subtitleSecondView: UILabel!
    @IBOutlet weak var moreButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        skeletonable(true)
        artworkImageView.drawBorder(8, width: 0.5, color: .adaptableBorder)
        titleView.textColor = .label
        subtitleView.textColor = .secondaryLabel
        subtitleSecondView.textColor = .secondaryLabel
        
        titleView.font = UIFont.systemFont(ofSize: 16, weight: UIFont.Weight(0.25))
        contentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didOpenPlaylist)))
        
        moreButton.setTitle("", for: .normal)
        moreButton.setImage(.init(named: "more-horizontal")?.tint(with: .getAccentColor(fromType: .common)), for: .normal)
    }
    
    override func configure(with item: Playlist) {
        artworkImageView.kf.setImage(with: item.photo?.photo270?.toUrl())
        titleView.text = item.title
        subtitleView.text = item.mainArtists?.compactMap { $0.name }.joined(separator: ", ")
        
        let secondSubtitle = "\(item.year ?? 0)"
        subtitleSecondView.text = secondSubtitle
        
        skeletonable(false)
    }

    func skeletonable(_ state: Bool) {
        if state {
            artworkImageView.showAnimatedGradientSkeleton()
            titleView.showAnimatedGradientSkeleton()
            subtitleView.showAnimatedGradientSkeleton()
            subtitleSecondView.showAnimatedGradientSkeleton()
        } else {
            artworkImageView.hideSkeleton()
            titleView.hideSkeleton()
            subtitleView.hideSkeleton()
            subtitleSecondView.hideSkeleton()
            
            artworkImageView.drawBorder(8, width: 0.5, color: .adaptableBorder)
            titleView.textColor = .label
            subtitleView.textColor = .secondaryLabel
            subtitleSecondView.textColor = .secondaryLabel
        }
    }
    
    @objc func didOpenPlaylist() {
        delegate?.perform(from: self)
    }
}
