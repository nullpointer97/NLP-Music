//
//  VKBaseViewCell.swift
//  vkmusic
//
//  Created by Ярослав Стрельников on 02.02.2022.
//  Copyright © 2022 NP-Team. All rights reserved.
//

import UIKit

enum ListViewCell: String {
    case audio = "VKAudioViewCell"
    case miniAudio = "VKMiniAudioViewCell"
    case playlist = "VKPlaylistCollectionViewCell"
    case colorPicker = "ColorPickerViewCell"
    case control = "ControlViewCell"
    case pairButton = "VKPairButtonViewCell"
}

class VKBaseViewCell<T>: UITableViewCell {
    var morePlaceholderButton: UIButton = UIButton()
    weak var delegate: VKMBaseItemDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func configure(with item: T) {}
}

class VKBaseCollectionViewCell<T>: UICollectionViewCell {
    weak var delegate: VKMBaseItemDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func configure(with item: T) {}
}

enum SettingType {
    case plain
    case `switch`
    case anotherView
    case additionalText(ActionType?)
    case action(ActionType)
}

class VKBaseSettingViewCell: UITableViewCell {
    var type: SettingType = .plain
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
