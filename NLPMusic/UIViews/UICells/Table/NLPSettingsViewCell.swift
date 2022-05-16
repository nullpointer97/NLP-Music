//
//  VKSettingsViewCell.swift
//  vkmusic
//
//  Created by Ярослав Стрельников on 04.02.2022.
//  Copyright © 2022 NP-Team. All rights reserved.
//

import UIKit

protocol SettingActionDelegate: AnyObject {
    func didChangeSetting(_ cell: NLPSettingViewCell, forKey key: String, value: Bool)
    func didTap(_ cell: NLPSettingViewCell)
}

class NLPSettingsViewCell: NLPBaseSettingViewCell {
    override var type: SettingType {
        didSet {
            switch type {
            case .switch:
                switchConstraint.constant = 16
                settingSwitch.isHidden = false
                additionalLabel?.isHidden = true
            case .plain:
                switchConstraint.constant = -50
                settingSwitch.isHidden = true
                additionalLabel?.isHidden = true
            case .additionalText:
                switchConstraint.constant = -50
                settingSwitch.isHidden = true
                additionalLabel?.isHidden = false
            case .action(_):
                switchConstraint.constant = -50
                settingSwitch.isHidden = true
                additionalLabel?.isHidden = true
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
    @IBOutlet weak var additionalLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        contentView.isUserInteractionEnabled = true
        contentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTap(_:))))
    }
    
    func configure(_ setting: SettingViewModel) {
        alpha = setting.isEnabled ? 1 : 0.5
        isUserInteractionEnabled = setting.isEnabled
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 15.5),
            .foregroundColor: setting.settingColor
        ]
        
        let secondAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 13),
            .foregroundColor: UIColor.secondaryLabel
        ]
        
        titleLabel.attributedText = NSAttributedString(string: setting.title, attributes: attributes)
        titleLabel.sizeToFit()
        
        settingKey = setting.key
        
        switch setting.type {
        case .plain, .action(_):
            break
        case .anotherView:
//            colorNode.backgroundColor = .getAccentColor(fromType: .common)
            break
        case .switch:
            DispatchQueue.main.async { [weak self] in
                self?.settingSwitch.isOn = setting.setting as? Bool ?? setting.defaultValue
            }
        case .additionalText:
            additionalLabel?.attributedText = NSAttributedString(string: "\(setting.subtitle)", attributes: secondAttributes)
        }
        type = setting.type
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    @objc func didTap(_ gestureRecognizer: UITapGestureRecognizer) {
    }

    @IBAction func onChangeSetting(_ sender: UISwitch) {
    }
}
