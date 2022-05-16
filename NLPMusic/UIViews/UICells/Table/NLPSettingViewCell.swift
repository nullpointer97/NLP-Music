//
//  NLPSettingViewCell.swift
//  NLPMusic
//
//  Created by Ярослав Стрельников on 25.04.2022.
//  Copyright © 2022 NP-Team. All rights reserved.
//

import UIKit

class NLPSettingViewCell: NLPBaseViewCell<SettingViewModel> {
    @IBOutlet weak var settingImageView: UIImageView!
    @IBOutlet weak var settingTitleLabel: UILabel!
    @IBOutlet weak var settingSubtitleLabel: UILabel!
    @IBOutlet weak var settingSwitch: UISwitch!
    @IBOutlet weak var switchConstraint: NSLayoutConstraint!
    @IBOutlet weak var colorView: UIView!
    
    var type: SettingType = .plain {
        didSet {
            switch type {
            case .switch:
                switchConstraint?.constant = 75
                settingSwitch?.isHidden = false
                settingSubtitleLabel?.isHidden = true
                colorView?.isHidden = true
            case .plain:
                switchConstraint.constant = 10
                settingSwitch.isHidden = true
                settingSubtitleLabel?.isHidden = true
                colorView?.isHidden = true
            case .additionalText:
                switchConstraint.constant = 10
                settingSwitch.isHidden = true
                settingSubtitleLabel?.isHidden = false
                colorView?.isHidden = true
            case .action(_):
                switchConstraint.constant = 10
                settingSwitch.isHidden = true
                settingSubtitleLabel?.isHidden = true
                colorView?.isHidden = true
            case .anotherView:
                switchConstraint.constant = 56
                settingSwitch.isHidden = true
                settingSubtitleLabel?.isHidden = true
                colorView?.isHidden = false
            }
        }
    }
    var settingKey: String = ""
    weak var settingDelegate: SettingActionDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        settingImageView.drawBorder(8, width: 0)
        colorView.drawBorder(15, width: 0.5, color: .adaptableBorder)
        
        contentView.isUserInteractionEnabled = true
        contentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTap(_:))))
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    override func configure(with item: SettingViewModel) {
        settingImageView.backgroundColor = item.imageColor
        settingImageView.image = .init(named: item.image ?? "")?.tint(with: .white)?.resize(toWidth: 20)?.resize(toHeight: 20)
        
        contentView.alpha = item.isEnabled ? 1 : 0.5
        contentView.isUserInteractionEnabled = item.isEnabled
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 15.5),
            .foregroundColor: item.settingColor
        ]
        
        let secondAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 13),
            .foregroundColor: UIColor.secondaryLabel
        ]
        
        settingTitleLabel.attributedText = NSAttributedString(string: item.title, attributes: attributes)
        settingTitleLabel.sizeToFit()

        settingKey = item.key
        
        switch item.type {
        case .plain, .action(_):
            break
        case .anotherView:
            colorView.backgroundColor = .getAccentColor(fromType: .common)
        case .switch:
            settingSwitch.isOn = item.setting as? Bool ?? item.defaultValue
            settingSwitch.onTintColor = .getAccentColor(fromType: .common)
        case .additionalText:
            settingSubtitleLabel?.attributedText = NSAttributedString(string: "\(item.subtitle)", attributes: secondAttributes)
            settingSubtitleLabel?.sizeToFit()
        }
        type = item.type
    }
    
    @objc func didTap(_ gestureRecognizer: UITapGestureRecognizer) {
        settingDelegate?.didTap(self)
    }
    
    @IBAction func didChangeSetting(_ sender: UISwitch) {
        settingDelegate?.didChangeSetting(self, forKey: settingKey, value: sender.isOn)
    }
}
