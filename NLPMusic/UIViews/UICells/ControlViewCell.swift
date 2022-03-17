//
//  ControlViewCell.swift
//  vkmusic
//
//  Created by Ярослав Стрельников on 15.02.2022.
//  Copyright © 2022 NP-Team. All rights reserved.
//

import UIKit

@objc protocol ControlDelegate: AnyObject {
    @objc optional func didChangeColorPickerIntense(_ sender: UISlider)
    @objc optional func didChangeEqualizerNode(_ cell: ControlViewCell, _ sender: UISlider)
}

enum ControlType {
    case equalizer
    case colorPicker
}

class ControlViewCell: VKBaseSettingViewCell {
    @IBOutlet weak var upperLimitLabel: UILabel!
    @IBOutlet weak var lowerLimitLabel: UILabel!
    @IBOutlet weak var frequencyNameLabel: UILabel!
    @IBOutlet weak var colorPickerIntenseSwitch: ProgressSlider!
    @IBOutlet weak var widthConstraint: NSLayoutConstraint!
    
    weak var delegate: ControlDelegate?
    
    var controlType: ControlType = .colorPicker
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        colorPickerIntenseSwitch.minimumTrackTintColor = .getAccentColor(fromType: .common)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    @IBAction func didChangeColorPickerIntense(_ sender: UISlider) {
        switch controlType {
        case .equalizer:
            delegate?.didChangeEqualizerNode?(self, sender)
        case .colorPicker:
            Settings.colorPickerElementSize = CGFloat(sender.value)
            delegate?.didChangeColorPickerIntense?(sender)
        }
    }
}
