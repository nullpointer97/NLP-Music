//
//  VKPlaylistCollectionViewCell.swift
//  vkmusic
//
//  Created by Ярослав Стрельников on 04.03.2022.
//  Copyright © 2022 NP-Team. All rights reserved.
//

import UIKit

class VKPlaylistCollectionViewCell: VKBaseCollectionViewCell<Playlist> {
    @IBOutlet weak var playlistImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        configureLayout()
    }

    override func configure(with item: Playlist) {
        playlistImageView.kf.setImage(with: URL(string: UIDevice.current.userInterfaceIdiom == .pad ? item.photo?.photo1200 : item.photo?.photo300))
        titleLabel.text = item.title
    }
    
    private func configureLayout() {
        playlistImageView.image = .init(named: "missing_song_artwork_generic_proxy")
        playlistImageView.drawBorder(12, width: 0)
    }
}
