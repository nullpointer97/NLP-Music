//
//  NLPGroupViewCell.swift
//  NLPMusic
//
//  Created by Ярослав Стрельников on 16.05.2022.
//  Copyright © 2022 NP-Team. All rights reserved.
//

import UIKit

class NLPGroupViewCell: NLPBaseCollectionViewCell<Group> {
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        photoImageView.drawBorder(24, width: 0.5, color: .adaptableBorder)
    }

    override func configure(with item: Group) {
        photoImageView.kf.setImage(with: item.image[1].url.toUrl())
        titleLabel.text = item.title
        subtitleLabel.text = item.subtitle
    }
}
