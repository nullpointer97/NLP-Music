//
//  PlaylistTableViewCell.swift
//  vkmusic
//
//  Created by Ярослав Стрельников on 04.03.2022.
//  Copyright © 2022 NP-Team. All rights reserved.
//

import UIKit

class VKPlaylistViewCell: VKBaseViewCell<Playlist> {
    @IBOutlet weak var playlistImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var genreLabel: UILabel!
    @IBOutlet weak var moreButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        configureLayout()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    override func configure(with item: Playlist) {
        playlistImageView.kf.setImage(with: URL(string: item.photo?.photo300))
        titleLabel.text = item.title
        genreLabel.text = item.genres.first?.name
    }
    
    private func configureLayout() {
        playlistImageView.drawBorder(8, width: 0)
    }

    @IBAction func didTapMoreButton(_ sender: UIButton) {
        
    }
}
