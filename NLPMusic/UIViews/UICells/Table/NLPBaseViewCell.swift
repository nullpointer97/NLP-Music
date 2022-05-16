//
//  NLPBaseViewCell.swift
//  vkmusic
//
//  Created by Ярослав Стрельников on 02.02.2022.
//  Copyright © 2022 NP-Team. All rights reserved.
//

import UIKit
import SwipeCellKit
import MaterialComponents

enum ListViewCell: String {
    case audio = "NLPAudioViewCell"
    case miniAudio = "NLPMiniAudioViewCell"
    case playlist = "NLPPlaylistCollectionViewCell"
    case colorPicker = "ColorPickerViewCell"
    case control = "ControlViewCell"
    case pairButton = "NLPPairButtonViewCell"
    case listPlaylist = "NLPPlaylistListViewCell"
    case smallUser = "NLPUserViewCell"
    case setting = "NLPSettingViewCell"
    case bigUser = "NLPSettingUserViewCell"
    case folder = "NLPFolderViewCell"
    case collectionAudio = "NLPAudioCollectionViewCell"
    case collectionAlbum = "NLPLargeAlbumViewCell"
    case collectionLargeImage = "NLPLargeImageViewCell"
    case collectionGroup = "NLPGroupViewCell"
}

class NLPBaseViewCell<T>: SwipeTableViewCell {
    var morePlaceholderButton: UIButton = UIButton()
    weak var _delegate: VKMBaseItemDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func configure(with item: T) {}
}

class NLPBaseCollectionViewCell<T>: MDCCollectionViewCell {
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

class NLPBaseSettingViewCell: UITableViewCell {
    var type: SettingType = .plain
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
