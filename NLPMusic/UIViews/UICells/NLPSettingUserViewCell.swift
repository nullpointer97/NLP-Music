//
//  NLPSettingUserViewCell.swift
//  NLPMusic
//
//  Created by Ярослав Стрельников on 25.04.2022.
//  Copyright © 2022 NP-Team. All rights reserved.
//

import UIKit

class NLPSettingUserViewCell: NLPBaseViewCell<NLPUser> {
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var nicknameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()

        avatarImageView.drawBorder(30, width: 0.5, color: .adaptableBorder)
        nicknameLabel.textColor = .getAccentColor(fromType: .common)
        
        for view in contentView.subviews {
            view.showAnimatedGradientSkeleton()
            view.startSkeletonAnimation()
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    override func configure(with item: NLPUser) {
        avatarImageView.kf.setImage(with: URL(string: item.photo200))
        nameLabel.text = item.firstNameNom + " " + item.lastNameNom
        nicknameLabel.text = "@\(item.screenName ?? "\(item.id)")"
        nicknameLabel.textColor = .getAccentColor(fromType: .common)
        
        for view in contentView.subviews {
            view.hideSkeleton()
        }
    }
}
