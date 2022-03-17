//
//  VKSettingsViewCell.swift
//  vkmusic
//
//  Created by Ярослав Стрельников on 04.02.2022.
//  Copyright © 2022 NP-Team. All rights reserved.
//

import UIKit

protocol SettingActionDelegate: AnyObject {
    func didChangeSetting(_ cell: VKSettingsViewCell, forKey key: String, value: Bool)
    func didTap(_ cell: VKSettingsViewCell)
}

class VKSettingsViewCell: VKBaseSettingViewCell {
    override var type: SettingType {
        didSet {
            switch type {
            case .switch:
                switchConstraint.constant = 16
                settingSwitch.isHidden = false
                aditionalLabel.isHidden = true
            case .plain:
                switchConstraint.constant = -50
                settingSwitch.isHidden = true
                aditionalLabel.isHidden = true
            case .additionalText:
                switchConstraint.constant = -50
                settingSwitch.isHidden = true
                aditionalLabel.isHidden = false
            case .action(_):
                switchConstraint.constant = -50
                settingSwitch.isHidden = true
                aditionalLabel.isHidden = true
            case .anotherView:
                break
            }
        }
    }
    var settingKey: String = ""
    weak var delegate: SettingActionDelegate?
    
    @IBOutlet weak var switchConstraint: NSLayoutConstraint!
    @IBOutlet weak var settingSwitch: UISwitch!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var aditionalLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        contentView.isUserInteractionEnabled = true
        contentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTap(_:))))
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    @objc func didTap(_ gestureRecognizer: UITapGestureRecognizer) {
        delegate?.didTap(self)
    }

    @IBAction func onChangeSetting(_ sender: UISwitch) {
        delegate?.didChangeSetting(self, forKey: settingKey, value: sender.isOn)
    }
}
