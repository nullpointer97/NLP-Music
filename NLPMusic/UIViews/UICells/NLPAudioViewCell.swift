//
//  NLPAudioViewCell.swift
//  NLPMusic
//
//  Created by Ярослав Стрельников on 04.04.2022.
//  Copyright © 2022 NP-Team. All rights reserved.
//

import UIKit
import Lottie

protocol AudioItemActionDelegate: AnyObject {
    func didSaveAudio(_ item: AudioPlayerItem, indexPath: IndexPath)
    func didRemoveAudio(_ item: AudioPlayerItem, indexPath: IndexPath)
}

protocol MenuDelegate: AnyObject {
    func didOpenMenu(audio cell: NLPBaseViewCell<AudioPlayerItem>)
    func didOpenMenu(playlist cell: NLPBaseViewCell<Playlist>)
}

class NLPAudioViewCell: NLPBaseViewCell<AudioPlayerItem> {
    @IBOutlet weak var artistImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var artistNameLabel: UILabel!
    @IBOutlet weak var downloadedImage: UIImageView!
    @IBOutlet weak var trailingSecondConstraint: NSLayoutConstraint!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var downloadProgressRingView: UICircularProgressRingView!
    
    var playingAnimation: AnimationView!
    
    weak var menuDelegate: MenuDelegate?
    weak var downloadDelegate: DownloadItemProtocol?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        artistImageView.image = nil
        nameLabel.text = nil
        artistNameLabel.text = nil
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        downloadProgressRingView.maxValue = 100
        downloadProgressRingView.innerRingColor = .getAccentColor(fromType: .common)
        
        playingAnimation = AnimationView(animation: Animation.named("playing"))
        playingAnimation.backgroundBehavior = .pauseAndRestore
        playingAnimation.loopMode = .loop
        playingAnimation.drawBorder(4, width: 0)
        playingAnimation.add(to: artistImageView)
        playingAnimation.backgroundColor = .black.withAlphaComponent(0.25)
        playingAnimation.autoPinEdgesToSuperviewEdges()
        playingAnimation.viewportFrame = CGRect(x: -10, y: -10, width: artistImageView.bounds.width + 20, height: artistImageView.bounds.height + 20)
        
        artistImageView.backgroundColor = .musicBg
        artistImageView.drawBorder(4, width: 0.5, color: .adaptableBorder)
        
        durationLabel.font = .systemFont(ofSize: 13, weight: UIFont.Weight(0.25))
        durationLabel.textColor = .secondaryLabel
        
        artistNameLabel.font = .systemFont(ofSize: 13, weight: UIFont.Weight(0.25))
        artistNameLabel.textColor = .secondaryLabel

        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapAudio)))
        
        trailingSecondConstraint.constant = -28
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    override func configure(with item: AudioPlayerItem) {
        durationLabel.text = item.duration?.duration
        durationLabel.sizeToFit()

        nameLabel.attributedText =
                    NSAttributedString(string: item.title ?? "", attributes: [.font: UIFont.systemFont(ofSize: 17, weight: UIFont.Weight(0.25)), .foregroundColor: UIColor.label]) +
                    NSAttributedString(string: " ") +
                    NSAttributedString(string: item.subtitle ?? "", attributes: [.font: UIFont.systemFont(ofSize: 17, weight: UIFont.Weight(0.25)), .foregroundColor: UIColor.secondaryLabel])
        artistNameLabel.text = item.artist
        
        if let stringUrl = item.albumThumb135, !stringUrl.isEmpty, let url = URL(string: stringUrl) {
            artistImageView.kf.setImage(with: url)
        } else {
            artistImageView.image = .init(named: "playlist_outline_56")
        }
        
        setAnimation(isPlaying: item.isPlaying , isPaused: item.isPaused)
        
        downloadedImage.isHidden = !item.isDownloaded
        
        contentView.alpha = item.soundUrl != nil ? 1 : 0.5
    }
    
    func configure(withSavedItem item: AudioItem) {
        durationLabel.text = item.duration?.duration
        durationLabel.sizeToFit()

        nameLabel.attributedText =
                    NSAttributedString(string: item.title ?? "", attributes: [.font: UIFont.systemFont(ofSize: 17, weight: UIFont.Weight(0.25)), .foregroundColor: UIColor.label]) +
                    NSAttributedString(string: " ") +
                    NSAttributedString(string: item.subtitle ?? "", attributes: [.font: UIFont.systemFont(ofSize: 17, weight: UIFont.Weight(0.25)), .foregroundColor: UIColor.secondaryLabel])
        artistNameLabel.text = item.artist

        if let stringUrl = item.albumThumb135, !stringUrl.isEmpty, let url = URL(string: stringUrl) {
            artistImageView.kf.setImage(with: url)
        } else {
            artistImageView.image = .init(named: "missing_song_artwork_generic_proxy")
        }
        
        setAnimation(isPlaying: item.isPlaying ?? false, isPaused: item.isPaused ?? false)
        
        downloadedImage.isHidden = false
    }
    
    func setDownloadProcess(_ status: DownloadStatus, indexPath: IndexPath) {
        switch status {
        case .none, .completed, .failed:
            downloadProgressRingView.isHidden = true
            trailingSecondConstraint.constant = -28
        case .inProgress:
            tag = indexPath.row
            downloadProgressRingView.isHidden = false
            trailingSecondConstraint.constant = 12
        }
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
        downloadedImage.isHidden = !value
    }
    
    @objc func didTapAudio(_ sender: UIGestureRecognizer) {
        delegate?.didTap(self)
    }

    @IBAction func onOpenMenu(_ sender: UIButton) {
        menuDelegate?.didOpenMenu(audio: self)
    }

    @IBAction func didOpenMenu(_ sender: UIButton) {
        menuDelegate?.didOpenMenu(audio: self)
    }
}
