//
//  NLPPlaylistListViewCell.swift
//  NLPMusic
//
//  Created by Ярослав Стрельников on 29.03.2022.
//  Copyright © 2022 NP-Team. All rights reserved.
//

import UIKit

class NLPPlaylistListViewCell: NLPBaseViewCell<Playlist> {
    @IBOutlet weak var playlistArtworkImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var additionalLabel: UILabel!
    @IBOutlet weak var moreButton: UIButton!
    
    weak var menuDelegate: MenuDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        configureLayout()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        playlistArtworkImageView.drawBorder(6, width: 0.5, color: .adaptableBorder)
    }
    
    override func configure(with item: Playlist) {
        if let imageUrl = URL(string: item.photo?.photo300) {
            playlistArtworkImageView.kf.setImage(with: imageUrl)
        } else {
            playlistArtworkImageView.image = .init(named: "playlist_outline_56")
        }
            
        titleLabel.text = item.title
        artistLabel.text = item.mainArtists?.first?.name
        
        var additionalText: String

        let year = item.year?.stringValue ?? ""
        let plays = item.plays ?? 0 > 0 ? "\(item.plays ?? 0)" : ""
        
        if !year.isEmpty && !plays.isEmpty {
            additionalText = "\(year) · \(getStringByDeclension(number: item.plays, arrayWords: Localization.plays))"
        } else if year.isEmpty && !plays.isEmpty {
            additionalText = getStringByDeclension(number: item.plays, arrayWords: Localization.plays)
        } else if !year.isEmpty && plays.isEmpty {
            additionalText = year
        } else {
            additionalText = ""
        }
        
        additionalLabel.text = additionalText
    }
    
    @IBAction func onOpenMenu(_ sender: UIButton) {
        menuDelegate?.didOpenMenu(playlist: self)
    }
    
    func configureLayout() {
        moreButton.setImage(.init(named: "more-horizontal")?.tint(with: .getAccentColor(fromType: .common)), for: .normal)
        moreButton.setTitle("", for: .normal)
        moreButton.addTarget(self, action: #selector(onOpenMenu(_:)), for: .touchDown)

        playlistArtworkImageView.drawBorder(12, width: 0.4, color: .adaptableBorder)
        titleLabel.textColor = .label
        artistLabel.textColor = .getAccentColor(fromType: .common)
        additionalLabel.textColor = .secondaryLabel
        
        titleLabel.font = .systemFont(ofSize: 16, weight: UIFont.Weight(0.25))
        artistLabel.font = .systemFont(ofSize: 13, weight: .regular)
        additionalLabel.font = .systemFont(ofSize: 13, weight: .regular)
    }
}
