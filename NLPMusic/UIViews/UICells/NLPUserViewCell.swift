//
//  NLPUserViewCell.swift
//  NLPMusic
//
//  Created by Ярослав Стрельников on 21.04.2022.
//  Copyright © 2022 NP-Team. All rights reserved.
//

import UIKit

class NLPUserViewCell: NLPBaseViewCell<NLPUser> {
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        configureLayout()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    override func configure(with item: NLPUser) {
        avatarImageView.kf.setImage(with: URL(string: item.photo100))
        nameLabel.text = item.firstNameNom + " " + item.lastNameNom
    }
    
    func configureLayout() {
        avatarImageView.drawBorder(15, width: 0.5, color: .adaptableBorder)
        nameLabel.font = .systemFont(ofSize: 16, weight: UIFont.Weight(0.24))
    }
}
