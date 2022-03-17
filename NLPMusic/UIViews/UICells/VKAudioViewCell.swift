//
//  VKAudioViewCell.swift
//  vkmusic
//
//  Created by Ярослав Стрельников on 02.02.2022.
//  Copyright © 2022 NP-Team. All rights reserved.
//

import UIKit
import Lottie

protocol AudioItemActionDelegate: AnyObject {
    func didSaveAudio(_ item: AudioPlayerItem)
    func didRemoveAudio(_ item: AudioPlayerItem)
}

protocol MenuDelegate: AnyObject {
    func didOpenMenu(_ cell: VKBaseViewCell<AudioPlayerItem>)
}

class VKAudioViewCell: VKBaseViewCell<AudioPlayerItem> {
    @IBOutlet weak var artistImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var artistNameLabel: UILabel!
    @IBOutlet weak var moreButton: UIButton!
    @IBOutlet weak var downloadedImage: UIImageView!

    var playingAnimation: AnimationView!
    
    weak var menuDelegate: MenuDelegate?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        artistImageView.image = nil
        nameLabel.text = nil
        artistNameLabel.text = nil
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        morePlaceholderButton.add(to: contentView)
        morePlaceholderButton.isUserInteractionEnabled = false
        morePlaceholderButton.frame = moreButton.frame
        
        playingAnimation = AnimationView(animation: Animation.named("playing"))
        playingAnimation.backgroundBehavior = .pauseAndRestore
        playingAnimation.loopMode = .loop
        playingAnimation.drawBorder(8, width: 0)
        playingAnimation.add(to: artistImageView)
        playingAnimation.backgroundColor = .black.withAlphaComponent(0.25)
        playingAnimation.autoPinEdgesToSuperviewEdges()
        playingAnimation.viewportFrame = CGRect(x: -10, y: -10, width: artistImageView.bounds.width + 20, height: artistImageView.bounds.height + 20)
        
        artistImageView.backgroundColor = .musicBg
        artistImageView.drawBorder(8, width: 0.7, color: .adaptableBorder)
        
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapAudio)))
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    override func configure(with item: AudioPlayerItem) {
        moreButton.setImage(.init(named: "more-horizontal")?.tint(with: .secondBlack), for: .normal)
        moreButton.setTitle("", for: .normal)

        nameLabel.attributedText =
                    NSAttributedString(string: item.title ?? "", attributes: [.font: UIFont.systemFont(ofSize: 17, weight: .medium), .foregroundColor: UIColor.label]) +
                    NSAttributedString(string: " ") +
                    NSAttributedString(string: item.subtitle ?? "", attributes: [.font: UIFont.systemFont(ofSize: 17, weight: .regular), .foregroundColor: UIColor.secondaryLabel])
        artistNameLabel.text = item.artist
        if let stringUrl = item.albumThumb135, !stringUrl.isEmpty, let url = URL(string: stringUrl) {
            artistImageView.kf.setImage(with: url)
        } else {
            artistImageView.image = .init(named: "missing_song_artwork_generic_proxy")
        }
        
        setAnimation(isPlaying: item.isPlaying ?? false, isPaused: item.isPaused ?? false)
        
        downloadedImage.isHidden = !item.isDownloaded
        
        contentView.alpha = item.soundUrl != nil ? 1 : 0.5
    }
    
    func configure(withSavedItem item: AudioItem) {
        moreButton.setImage(.init(named: "more-horizontal")?.tint(with: .secondBlack), for: .normal)
        moreButton.setTitle("", for: .normal)

        nameLabel.text = item.title
        artistNameLabel.text = item.artist
        if let stringUrl = item.albumThumb135, !stringUrl.isEmpty, let url = URL(string: stringUrl) {
            artistImageView.kf.setImage(with: url)
        } else {
            artistImageView.image = .init(named: "missing_song_artwork_generic_proxy")
        }
        
        setAnimation(isPlaying: item.isPlaying ?? false, isPaused: item.isPaused ?? false)
        
        downloadedImage.isHidden = !item.isDownloaded
        
        contentView.alpha = item.soundUrl != nil ? 1 : 0.5
    }
    
    func setAnimation(isPlaying: Bool, isPaused: Bool) {
        if isPlaying {
            playingAnimation.isHidden = false
            playingAnimation.play()
        } else if isPaused {
            playingAnimation.isHidden = false
            playingAnimation.pause()
        } else {
            playingAnimation.isHidden = true
            playingAnimation.stop()
        }
    }
    
    func setDownloaded(_ value: Bool) {        
        UIView.animate(withDuration: 0.3, delay: 0, options: [.preferredFramesPerSecond60]) { [weak self] in
            self?.downloadedImage.isHidden = !value
        }
    }
    
    @objc func didTapAudio() {
        delegate?.didTap(self)
    }

    @IBAction func onOpenMenu(_ sender: UIButton) {
        menuDelegate?.didOpenMenu(self)
    }
}
