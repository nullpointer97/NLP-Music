//
//  NLPFolderViewCell.swift
//  NLPMusic
//
//  Created by Ярослав Стрельников on 12.05.2022.
//  Copyright © 2022 NP-Team. All rights reserved.
//

import UIKit

class NLPFolderViewCell: NLPBaseViewCell<AudioSectionItem> {
    @IBOutlet weak var folderImageView: UIImageView!
    @IBOutlet weak var folderName: UILabel!
    
    @IBOutlet weak var imageViewTopPadding: NSLayoutConstraint!
    @IBOutlet weak var imageViewBottomPadding: NSLayoutConstraint!

    override func awakeFromNib() {
        super.awakeFromNib()
        folderImageView.drawBorder(4, width: 0)
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapAudio)))
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    override func configure(with item: AudioSectionItem) {
        folderName.attributedText =
            NSAttributedString(string: item.title, attributes: [.font: UIFont.systemFont(ofSize: 17, weight: UIFont.Weight(0.25)), .foregroundColor: UIColor.label])
        folderImageView.image = item.image?.toImage()?.tint(with: .getAccentColor(fromType: .common))
    }
    
    func configure(with item: AudioSectionItem, isShuffle: Bool = false) {
        configure(with: item)
        folderName.textColor = isShuffle ? .getAccentColor(fromType: .common) : .label
        folderImageView.backgroundColor = isShuffle ? .secondaryButton : .clear
        imageViewTopPadding.constant = isShuffle ? 6 : 10
        imageViewBottomPadding.constant = isShuffle ? 6 : 10
        
        accessoryType = isShuffle ? .none : .disclosureIndicator
    }
    
    func configureShuffleButton() {
        folderImageView.image = "shuffle-2".toImage()?.tint(with: .getAccentColor(fromType: .common))
        folderName.textColor = .getAccentColor(fromType: .common)
        folderName.font = .systemFont(ofSize: 17, weight: UIFont.Weight(0.25))
        folderName.text = .localized(.shuffle)
        folderImageView.backgroundColor = .secondaryButton
        imageViewTopPadding.constant = 6
        imageViewBottomPadding.constant = 6
        
        accessoryType = .none
    }
    
    @objc func didTapAudio(_ sender: UIGestureRecognizer) {
        delegate?.perform(from: self)
    }
}

extension String {
    func toImage() -> UIImage? {
        return UIImage(named: self)
    }
}
