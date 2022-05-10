//
//  PlayerViewController.swift
//  vkmusic
//
//  Created by Ярослав Стрельников on 03.02.2022.
//  Copyright © 2022 NP-Team. All rights reserved.
//

import UIKit
import Kingfisher
import AVKit
import MediaPlayer
import MarqueeLabel
import ViewAnimator

protocol PlayerItemDelegate: AnyObject {
    func didLoadItem(_ player: AudioPlayer, item: AudioPlayerItem)
}

protocol PlayerChangesDelegate: AnyObject {
    func didSetItem(_ item: AudioPlayerItem)
}

class PlayerViewController: UIViewController, PlayerSliderProtocol {
    @IBOutlet weak var audioItemImage: UIImageView!
    @IBOutlet weak var audioItemImageBackdrop: UIImageView!
    @IBOutlet weak var previousImage: UIImageView!
    @IBOutlet weak var playImage: UIImageView!
    @IBOutlet weak var nextImage: UIImageView!
    @IBOutlet weak var isHQLabel: UILabel!
    @IBOutlet weak var timeElapsedLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var HQView: UIView!
    @IBOutlet weak var explicitView: UIView!
    @IBOutlet weak var volumeSlider: UISlider!
    @IBOutlet weak var progressView: PlayerSlider!
    @IBOutlet weak var optionsButton: UIButton!
    @IBOutlet weak var titleLabel: MarqueeLabel!
    @IBOutlet weak var artistLabel: MarqueeLabel!
    @IBOutlet weak var volMinImage: UIImageView!
    @IBOutlet weak var volMaxImage: UIImageView!
    @IBOutlet weak var leadingArtworkContraint: NSLayoutConstraint!
    @IBOutlet weak var trailingArtworkConstraint: NSLayoutConstraint!
    @IBOutlet weak var topArtworkContraint: NSLayoutConstraint!
    @IBOutlet weak var closeChevronView: UIView!
    @IBOutlet weak var listView: UITableView!
    @IBOutlet weak var bottomTitlesConstraint: NSLayoutConstraint!
    @IBOutlet weak var leadingTitlesConstaint: NSLayoutConstraint!
    @IBOutlet weak var topTitlesConstraint: NSLayoutConstraint!
    @IBOutlet weak var listBottomFirstConstraint: NSLayoutConstraint!
    @IBOutlet weak var listBottomSecondConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomButtonsStackView: UIStackView!
    @IBOutlet weak var timingView: UIView!
    @IBOutlet weak var controlButtonsStackView: UIStackView!
    @IBOutlet weak var volumeStackView: UIStackView!
    
    weak var audioViewController: VKAudioController?
    weak var delegate: PlayerChangesDelegate?
    var beeingSeek = false
    var hasDefaultPostition: Bool = false
    var hasExpandList: Bool = false
    var isFinding: Bool = false
    var previousOffset: CGFloat = 0
    
    var isDark = false {
        didSet {
            setNeedsStatusBarAppearanceUpdate()
        }
    }

    var item: AudioPlayerItem? {
        didSet {
            if let item = item {
                delegate?.didSetItem(item)
            }
        }
    }
    
    var queueItems: [AudioPlayerItem] {
        guard let player = AudioService.instance.player else { return [] }
        return player.items ?? []
    }

    var outputVolumeObserve: NSKeyValueObservation?
    let audioSession = AVAudioSession.sharedInstance()
    
    init(item: AudioPlayerItem?) {
        self.item = item
        super.init(nibName: "PlayerViewController", bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    deinit {
        outputVolumeObserve = nil
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return isDark ? .lightContent : .default
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setPlayerUI()
        setVolumeButtonListener()
        
        UIView.transition(with: self.audioItemImage, duration: 0.2, options: [.preferredFramesPerSecond60, .transitionCrossDissolve]) {
            self.audioItemImage.image = .init(named: "missing_song_artwork_generic_proxy")
        }
        UIView.transition(with: self.audioItemImageBackdrop, duration: 0.2, options: .preferredFramesPerSecond60) {
            self.audioItemImageBackdrop.image = .init(named: "missing_song_artwork_generic_proxy")?.applyDarkEffect()
            
            if self.audioItemImageBackdrop.image?.averageColor?.isLight ?? false {
                self.setPrimaryColorsFromControls(isLight: true)
            } else {
                self.setPrimaryColorsFromControls(isLight: false)
            }
        }
        
        timeElapsedLabel.text = Settings.lastPlayingTime.stringDuration
        timeElapsedLabel.sizeToFit()
        durationLabel.text = (Settings.lastPlayingTime - TimeInterval(item?.duration ?? 0)).stringDuration.replacingOccurrences(of: ":-", with: ":")
        durationLabel.sizeToFit()
        
        progressView.progress = Settings.lastProgress
        
        optionsButton.addTarget(self, action: #selector(didOpenMenu), for: .touchUpInside)
        closeChevronView.drawBorder(2.5, width: 0)
        
        listView.delegate = self
        listView.dataSource = self
        listView.register(UINib(nibName: "VKAudioViewCell", bundle: nil), forCellReuseIdentifier: "VKAudioViewCell")
        listView.separatorStyle = .none
        listView.alwaysBounceVertical = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setPlayerUI()
        
        if let item = item {
            setItemData(fromItem: item)
        }
        
        animatePlayer(!hasDefaultPostition)
        
        if hasExpandList {
            listBottomSecondConstraint.isActive = false
            listBottomFirstConstraint.isActive = true

            UIView.animate(withDuration: 0.3, delay: 0, options: [.preferredFramesPerSecond60, .beginFromCurrentState, .transitionCrossDissolve]) {
                self.bottomButtonsStackView.alpha = 1
                self.controlButtonsStackView.alpha = 1
                self.timingView.alpha = 1
                self.volumeStackView.alpha = 1
                self.progressView.alpha = 1
                
                self.listView.superview?.layoutIfNeeded()
            }
        } else {
            listBottomSecondConstraint.isActive = true
            listBottomFirstConstraint.isActive = false
            
            UIView.animate(withDuration: 0.3, delay: 0, options: [.preferredFramesPerSecond60, .beginFromCurrentState, .transitionCrossDissolve]) {
                self.bottomButtonsStackView.alpha = !self.hasDefaultPostition ? 1 : 0
                self.controlButtonsStackView.alpha = !self.hasDefaultPostition ? 1 : 0
                self.timingView.alpha = !self.hasDefaultPostition ? 1 : 0
                self.volumeStackView.alpha = !self.hasDefaultPostition ? 1 : 0
                self.progressView.alpha = !self.hasDefaultPostition ? 1 : 0
                
                self.listView.superview?.layoutIfNeeded()
            }
        }
    }
    
    private func setItemData(fromItem item: AudioPlayerItem) {
        guard isViewLoaded else { return }
        titleLabel.text = item.title
        artistLabel.text = item.artist
        
        HQView.isHidden = !(item.isHQ ?? false)
        explicitView.isHidden = !(item.isExplicit ?? false)

        progressView.duration = TimeInterval(item.duration?.doubleValue ?? 0)
        if let url = URL(string: item.albumThumb600) {
            KingfisherManager.shared.retrieveImage(with: url, options: nil) { receivedSize, totalSize in
                print(receivedSize, totalSize)
            } completionHandler: { result in
                switch result {
                case .success(let value):
                    UIView.transition(with: self.audioItemImage, duration: 0.2, options: [.preferredFramesPerSecond60, .transitionCrossDissolve]) {
                        self.audioItemImage.image = value.image
                    }
                    UIView.transition(with: self.audioItemImageBackdrop, duration: 0.2, options: .preferredFramesPerSecond60) {
                        self.audioItemImageBackdrop.image = value.image.applyDarkEffect()
                        self.setPrimaryColorsFromControls(isLight: self.audioItemImageBackdrop.image?.averageColor?.isLight ?? false)
                    }
                case .failure(let error):
                    print(error)
                    break
                }
            }
        } else {
            UIView.transition(with: self.audioItemImage, duration: 0.2, options: [.preferredFramesPerSecond60, .transitionCrossDissolve]) {
                self.audioItemImage.image = .init(named: "missing_song_artwork_generic_proxy")
            }
            UIView.transition(with: self.audioItemImageBackdrop, duration: 0.2, options: .preferredFramesPerSecond60) {
                self.audioItemImageBackdrop.image = .init(named: "missing_song_artwork_generic_proxy")?.applyDarkEffect()
                self.setPrimaryColorsFromControls(isLight: self.audioItemImageBackdrop.image?.averageColor?.isLight ?? false)
            }
        }
    }
    
    private func setPlayerUI() {
        setPrimaryColorsFromControls(isLight: false)
        progressView.delegate = self
        
        let volumeView = MPVolumeView(frame: CGRect(x: -2000, y: -2000, width: 0, height: 0))
        volumeView.isUserInteractionEnabled = false
        volumeView.alpha = 0.1
        volumeView.add(to: view)
        
        volumeSlider.value = AVAudioSession.sharedInstance().outputVolume
        
        audioItemImage.drawBorder(12, width: 0)
        
        HQView.isHidden = true
        explicitView.isHidden = true
        
        optionsButton.drawBorder(16, width: 0)
        optionsButton.setTitle("", for: .normal)
        
        view.bringSubviewToFront(audioItemImage)
        
        previousImage.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(previousTrack(_:))))
        playImage.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(playOrResume(_:))))
        nextImage.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(nextTrack(_:))))
        
        view.layoutIfNeeded()
    }
    
    private func setPrimaryColorsFromControls(isLight: Bool) {
        isDark = !isLight
        HQView.drawBorder(6, width: 0.5, color: (isLight ? UIColor.black : UIColor.white).withAlphaComponent(0.2))
        
        explicitView.drawBorder(6, width: 0.5, color: (isLight ? UIColor.black : UIColor.white).withAlphaComponent(0.2))

        volMinImage.image = .init(named: "speaker.fill")?.tint(with: isLight ? .black : .white)
        volMaxImage.image = .init(named: "speaker.3.fill")?.tint(with: isLight ? .black : .white)
        
        optionsButton.setImage(.init(named: "more-horizontal")?.tint(with: isLight ? .black : .white), for: .normal)

        previousImage.image = UIImage(named: "Backward Fill")?.tint(with: isLight ? .black : .white)
        
        if let player = AudioService.instance.player {
            playImage.image = UIImage(named: player.currentItem?.isPlaying ?? false ? "Pause Fill" : "Play Fill")?.tint(with: isLight ? .black : .white)
        }
        
        nextImage.image = UIImage(named: "Forward Fill")?.tint(with: isLight ? .black : .white)
    }
    
    private func setVolumeButtonListener() {
        do {
            try audioSession.setActive(true)
        } catch {}

        outputVolumeObserve = audioSession.observe(\.outputVolume) { [weak self] (audioSession, changes) in
            guard let self = self else { return }
            self.volumeSlider.value = audioSession.outputVolume
        }
    }
    
    @IBAction func onVolumeChanged(_ sender: UISlider) {
        MPVolumeView.setVolume(sender.value)
    }
    
    func onValueChanged(progress: Float, timePast: TimeInterval) {
        guard let player = AudioService.instance.player else {
            beeingSeek = false
            return
        }
        beeingSeek = true
        
        let playerRate = player.rate
        
        player.seek(to: TimeInterval(item?.duration ?? 0) * TimeInterval(progress)) { success in
            if success {
                player.rate = playerRate
            }
        }
    }

    @objc func handleSliderChange(_ sender: ProgressSlider) {
        guard let player = AudioService.instance.player else {
            return
        }
        
        let playerRate = player.rate
        
        player.seek(to: Double(sender.value)) { success in
            if success {
                player.rate = playerRate
            }
        }
    }
    
    @objc func playOrResume(_ recognizer: UITapGestureRecognizer) {
        guard let player = AudioService.instance.player else { return }
        guard let item = item else {
            return
        }
        let items = audioViewController?.audioItems ?? []

        switch player.state {
        case .buffering:
            log("item buffering", type: .debug)
        case .playing:
            player.pause()
        case .paused:
            player.resume()
        case .stopped where Settings.lastPlayingTime == 0, .stopped:
            player.play(items: items, startAtIndex: items.firstIndex(of: item) ?? 0)
        case .stopped where Settings.lastPlayingTime > 0:
            player.resume(items: items, startAtIndex: items.firstIndex(of: item) ?? 0)
        case .waitingForConnection:
            log("player wait connection", type: .warning)
        case .failed(let error):
            log(error.localizedDescription, type: .error)
        }
    }
    
    @objc func nextTrack(_ recognizer: UITapGestureRecognizer) {
        guard let player = AudioService.instance.player else {
            return
        }
        
        player.nextOrStop()
    }
    
    @objc func previousTrack(_ recognizer: UITapGestureRecognizer) {
        guard let player = AudioService.instance.player, player.hasPrevious else {
            return
        }
        
        player.previous()
    }
    
    @objc func didOpenMenu() {
        guard let item = item else {
            return
        }

        let menu = MenuViewController(from: item)
        menu.actionDelegate = self
        menu.actions = [
            !item.isDownloaded ? [AudioItemAction(actionDescription: "save", title: "Сохранить", action: { item in
                print("Save audio...")
            })] : [AudioItemAction(actionDescription: "remove", title: "Удалить", action: { item in
                print("Removing audio...")
            })]
        ]
        
        ContextMenu.shared.show(
            sourceViewController: self,
            viewController: menu,
            options: ContextMenu.Options(
                containerStyle: ContextMenu.ContainerStyle(backgroundColor: .contextColor),
                menuStyle: .default,
                hapticsStyle: .medium,
                position: .centerX
            ),
            sourceView: optionsButton,
            delegate: nil
        )
    }
    
    @IBAction func animtePlayerAction(_ sender: Any) {
        hasDefaultPostition.toggle()
        animatePlayer(!hasDefaultPostition)
    }
    
    private func animatePlayer(_ needDefault: Bool) {
        leadingArtworkContraint.constant = needDefault ? 64 : 24
        trailingArtworkConstraint.constant = needDefault ? 64 : view.frame.width / 1.4

        UIView.animate(withDuration: 0.3, delay: 0, options: [.preferredFramesPerSecond60, .beginFromCurrentState, .curveEaseOut, .transitionCrossDissolve]) {
            self.audioItemImage.superview?.layoutIfNeeded()
        }
        
        topTitlesConstraint.isActive = !needDefault
        bottomTitlesConstraint.isActive = needDefault
        
        leadingTitlesConstaint.constant = needDefault ? 32 : (36 + audioItemImage.bounds.size.width)
        
        listBottomSecondConstraint.isActive = needDefault
        listBottomFirstConstraint.isActive = !needDefault
        
        UIView.animate(withDuration: 0.3, delay: 0, options: [.preferredFramesPerSecond60, .beginFromCurrentState, .curveEaseOut, .transitionCrossDissolve]) {
            self.listView.alpha = needDefault ? 0 : 1
            self.audioItemImage.superview?.layoutIfNeeded()
        }
    }
    
    func changePlayButton() {
        guard let player = AudioService.instance.player else { return }
        UIView.transition(.promise, with: playImage, duration: 0.2) {
            self.playImage.image = UIImage(named: player.currentItem?.isPlaying ?? false ? "Pause Fill" : "Play Fill")?.tint(with: .white)
            self.playImage.layoutIfNeeded()
        }
    }
}

extension PlayerViewController: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isFinding = true
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if (isFinding) {
            if (previousOffset == 0) {
                previousOffset = listView.contentOffset.y
                
            } else {
                let diff = listView.contentOffset.y - previousOffset;
                if diff != 0 {
                    previousOffset = 0
                    isFinding = false
                    
                    if (diff > 0) {
                        hasExpandList = false

                        listBottomSecondConstraint.isActive = true
                        listBottomFirstConstraint.isActive = false
                        
                        UIView.animate(withDuration: 0.35, delay: 0, options: [.preferredFramesPerSecond60, .beginFromCurrentState, .transitionCrossDissolve]) {
                            self.bottomButtonsStackView.alpha = 0
                            self.controlButtonsStackView.alpha = 0
                            self.timingView.alpha = 0
                            self.volumeStackView.alpha = 0
                            self.progressView.alpha = 0
                            
                            self.listView.superview?.layoutIfNeeded()
                        }
                    } else {
                        hasExpandList = true
                        
                        listBottomSecondConstraint.isActive = false
                        listBottomFirstConstraint.isActive = true
                        
                        UIView.animate(withDuration: 0.35, delay: 0, options: [.preferredFramesPerSecond60, .beginFromCurrentState, .transitionCrossDissolve]) {
                            self.bottomButtonsStackView.alpha = 1
                            self.controlButtonsStackView.alpha = 1
                            self.timingView.alpha = 1
                            self.volumeStackView.alpha = 1
                            self.progressView.alpha = 1
                            
                            self.listView.superview?.layoutIfNeeded()
                        }
                    }
                }
            }
        }
    }
}

extension PlayerViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        queueItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "VKAudioViewCell", for: indexPath) as? VKAudioViewCell else { return UITableViewCell() }
        cell.configure(with: queueItems[indexPath.row])
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear
        cell.nameLabel.textColor = .white
        cell.moreButton.setImage(.init(named: "more-horizontal")?.tint(with: .white), for: .normal)
        cell.moreButton.setTitle("", for: .normal)
        cell.artistNameLabel.textColor = .white.withAlphaComponent(0.5)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        56
    }
}

extension PlayerViewController: PlayerItemDelegate {
    func didLoadItem(_ player: AudioPlayer, item: AudioPlayerItem) {
        setItemData(fromItem: item)
    }
}

extension PlayerViewController: AudioItemActionDelegate {
    func didSaveAudio(_ item: AudioPlayerItem) {
        ContextMenu.shared.dismiss()
        
        do {
            try item.downloadAudio()
        } catch {
            print(error)
        }
    }
    
    func didRemoveAudio(_ item: AudioPlayerItem) {
        ContextMenu.shared.dismiss()
        
        do {
            try item.removeAudio()
        } catch {
            print(error)
        }
    }
}

extension MPVolumeView {
    static func setVolume(_ volume: Float) {
        let volumeView = MPVolumeView(frame: .zero)
        let slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.01) {
            slider?.value = volume
        }
    }
}

extension UIImageView {
    func applyshadowWithCorner(containerView: UIView, cornerRadious: CGFloat) {
        containerView.clipsToBounds = false
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.5
        containerView.layer.shadowOffset = .custom(5, -2)
        containerView.layer.shadowRadius = 20
        containerView.layer.cornerRadius = cornerRadious
        containerView.layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadious).cgPath
        self.clipsToBounds = true
        self.layer.cornerRadius = cornerRadious
    }
}
