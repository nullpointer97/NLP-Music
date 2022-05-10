//
//  VKMiniAudioViewCell.swift
//  vkmusic
//
//  Created by Ярослав Стрельников on 05.03.2022.
//  Copyright © 2022 NP-Team. All rights reserved.
//

import UIKit
import Lottie

class VKMiniAudioViewCell: NLPBaseViewCell<AudioPlayerItem> {
    @IBOutlet weak var indexLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var animationView: AnimationView!
    
    weak var menuDelegate: MenuDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        configureLayout()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    override func configure(with item: AudioPlayerItem) {
        titleLabel.attributedText =
        NSAttributedString(string: item.title ?? "", attributes: [.font: UIFont.systemFont(ofSize: 17, weight: .medium), .foregroundColor: UIColor.label]) +
        NSAttributedString(string: " ") +
        NSAttributedString(string: item.subtitle ?? "", attributes: [.font: UIFont.systemFont(ofSize: 17, weight: .regular), .foregroundColor: UIColor.secondaryLabel])
        timeLabel.text = item.duration?.duration
        timeLabel.sizeToFit()
        
        setAnimation(isPlaying: item.isPlaying ?? false, isPaused: item.isPaused ?? false)
    }
    
    private func configureLayout() {
        animationView.backgroundColor = .getAccentColor(fromType: .common).withAlphaComponent(0.5)
        animationView.loopMode = .loop
        animationView.backgroundBehavior = .pauseAndRestore

        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapAudio)))
    }
    
    private func setAnimation(isPlaying: Bool, isPaused: Bool) {
        if isPlaying {
            indexLabel.isHidden = true
            animationView.isHidden = false
            animationView.play()
        } else if isPaused {
            indexLabel.isHidden = true
            animationView.isHidden = false
            animationView.pause()
        } else {
            indexLabel.isHidden = false
            animationView.isHidden = true
            animationView.stop()
        }
    }
    
    @objc func didTapAudio() {
        delegate?.didTap(self)
    }

    @IBAction func onOpenMenu(_ sender: UIButton) {
        menuDelegate?.didOpenMenu(audio: self)
    }
}
