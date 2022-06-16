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
    @IBOutlet weak var verifiedIcon: UIImageView!
    @IBOutlet weak var verifiedContraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        photoImageView.drawBorder(24, width: 0.5, color: .adaptableBorder)
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: UIFont.Weight(0.25))
        
        contentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didPerformToGroup)))
    }

    override func configure(with item: Group) {
        photoImageView.kf.setImage(with: item.image[1].url.toUrl())
        titleLabel.text = item.title
        titleLabel.sizeToFit()
        subtitleLabel.text = item.subtitle
        
        verifiedIcon.isHidden = !item.isVerified
        verifiedContraint.constant = item.isVerified ? 16 : 0
    }
    
    @objc func didPerformToGroup() {
        delegate?.perform(from: self)
    }
}
