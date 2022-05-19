//
//  NLPAudioCollectionViewCell.swift
//  NLPMusic
//
//  Created by Ярослав Стрельников on 15.05.2022.
//  Copyright © 2022 NP-Team. All rights reserved.
//

import UIKit
import Lottie

class NLPAudioCollectionViewCell: NLPBaseCollectionViewCell<AudioPlayerItem> {
    @IBOutlet weak var artworkImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var moreButton: UIButton!
    
    var playingAnimation: AnimationView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        skeletonable(true)

        playingAnimation = AnimationView(animation: Animation.named("playing"))
        playingAnimation.backgroundBehavior = .pauseAndRestore
        playingAnimation.loopMode = .loop
        playingAnimation.drawBorder(4, width: 0)
        playingAnimation.add(to: artworkImageView)
        playingAnimation.backgroundColor = .black.withAlphaComponent(0.25)
        playingAnimation.autoPinEdgesToSuperviewEdges()
        playingAnimation.viewportFrame = CGRect(x: -10, y: -10, width: artworkImageView.bounds.width + 20, height: artworkImageView.bounds.height + 20)
        
        artworkImageView.backgroundColor = .musicBg
        artworkImageView.drawBorder(4, width: 0.5, color: .adaptableBorder)

        titleLabel.textColor = .label
        artistLabel.textColor = .secondaryLabel
        
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: UIFont.Weight(0.25))
        contentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didPlayAudio)))
        
        moreButton.setTitle("", for: .normal)
        moreButton.setImage(.init(named: "more-horizontal")?.tint(with: .getAccentColor(fromType: .common)), for: .normal)
    }

    override func configure(with item: AudioPlayerItem) {
        artworkImageView.kf.setImage(with: item.albumThumb135?.toUrl())
        titleLabel.text = item.title
        artistLabel.text = item.artist
        
        setAnimation(isPlaying: item.isPlaying , isPaused: item.isPaused)
        
        skeletonable(false)
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

    func skeletonable(_ state: Bool) {
        if state {
            moreButton.isHidden = true
            artworkImageView.showAnimatedGradientSkeleton()
            titleLabel.showAnimatedGradientSkeleton()
            artistLabel.showAnimatedGradientSkeleton()
        } else {
            moreButton.isHidden = false

            artworkImageView.hideSkeleton()
            titleLabel.hideSkeleton()
            artistLabel.hideSkeleton()
            
            artworkImageView.drawBorder(4, width: 0.5, color: .adaptableBorder)
            titleLabel.textColor = .label
            artistLabel.textColor = .secondaryLabel
        }
    }
    
    @objc func didPlayAudio() {
        delegate?.didTap(self)
    }
}
