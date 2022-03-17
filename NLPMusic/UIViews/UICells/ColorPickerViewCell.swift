//
//  ColorPickerViewCell.swift
//  vkmusic
//
//  Created by Ярослав Стрельников on 15.02.2022.
//  Copyright © 2022 NP-Team. All rights reserved.
//

import UIKit

class ColorPickerViewCell: VKBaseSettingViewCell {
    @IBOutlet weak var colorPicker: HSBColorPicker!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        colorPicker.drawBorder(12, width: 0)
        colorPicker.elementSize = Settings.colorPickerElementSize
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
