//
//  BetaPlayerViewController.swift
//  vkmusic
//
//  Created by Ярослав Стрельников on 21.02.2022.
//  Copyright © 2022 NP-Team. All rights reserved.
//

import UIKit
import MarqueeLabel
import Kingfisher
import AVKit
import MediaPlayer
import CoreImage.CIFilterBuiltins
import SPAlert

enum SongDataState {
    case mini
    case full
}

enum RepeatMode {
    case repeatAll
    case repeatOne
    case noRepeat
}

enum ShuffleMode {
    case enabled
    case disabled
}

class BetaPlayerViewController: VKBaseViewController, AudioPlayerDelegate {
    @IBOutlet weak var titleLabel: MarqueeLabel!
    @IBOutlet weak var artistLabel: MarqueeLabel!
    @IBOutlet weak var artworkBackdropImageView: UIImageView!
    @IBOutlet weak var progressView: PlayerSlider!
    @IBOutlet weak var artworkImageView: UIImageView!
    @IBOutlet weak var timeElapsedLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var previousImage: UIImageView!
    @IBOutlet weak var playImage: UIImageView!
    @IBOutlet weak var nextImage: UIImageView!
    @IBOutlet weak var repeatButton: UIButton!
    @IBOutlet weak var shuffleButton: UIButton!
    @IBOutlet weak var moreButton: UIButton!
    
    var currentTabString: String = ""
    var currentArtworkImage: UIImage? = nil
    
    let context = CIContext()
    var beeingSeek = false
    var item: AudioPlayerItem? 
    var queueItems: [AudioPlayerItem] = []
    var outputVolumeObserve: NSKeyValueObservation?
    let audioSession = AVAudioSession.sharedInstance()
    var isListOpened: Bool = false
    
    weak var vkTabBarController: VKTabController?
    
    deinit {
        outputVolumeObserve = nil
        NotificationCenter.default.removeObserver(self)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func getIndexPath(byItem item: AudioPlayerItem) -> IndexPath? {
        guard let index = queueItems.firstIndex(of: item) else { return nil }
        return IndexPath(row: index, section: 0)
    }
    
    func audioPlayer(_ audioPlayer: AudioPlayer, shouldStartPlaying item: AudioPlayerItem) -> Bool {
        return true
    }
    
    func audioPlayer(_ audioPlayer: AudioPlayer, willStartPlaying item: AudioPlayerItem) {
        DispatchQueue.main.async { [self] in
            guard let indexPath = getIndexPath(byItem: item) else { return }
            
            self.item = item
            changePlayButton()
            updatePlayItem(byIndexPath: indexPath)
        }
    }
    
    func audioPlayer(_ audioPlayer: AudioPlayer, willStopPlaying item: AudioPlayerItem) {
        DispatchQueue.main.async { [self] in
            guard let indexPath = getIndexPath(byItem: item) else { return }
            updatePlayItem(byIndexPath: indexPath)
        }
    }
    
    func audioPlayer(_ audioPlayer: AudioPlayer, willPausePlaying item: AudioPlayerItem) {
        DispatchQueue.main.async { [self] in
            guard let indexPath = getIndexPath(byItem: item) else { return }
            changePlayButton()
            updatePlayItem(byIndexPath: indexPath)
        }
    }
    
    func audioPlayer(_ audioPlayer: AudioPlayer, willResumePlaying item: AudioPlayerItem) {
        DispatchQueue.main.async { [self] in
            guard let indexPath = getIndexPath(byItem: item) else { return }
            changePlayButton()
            updatePlayItem(byIndexPath: indexPath)
        }
    }
    
    func audioPlayer(_ audioPlayer: AudioPlayer, didUpdateProgressionTo time: TimeInterval, percentageRead: Float) {
        DispatchQueue.main.async { [self] in
            guard let duration = audioPlayer.currentItem?.duration else { return }

            progressView.progress = percentageRead / 100
            timeElapsedLabel.text = time.stringDuration
            timeElapsedLabel.sizeToFit()
            durationLabel.text = (time - Double(duration)).stringDuration.replacingOccurrences(of: ":-", with: ":")
            durationLabel.sizeToFit()
        }
    }
    
    func audioPlayer(_ audioPlayer: AudioPlayer, didFindDuration duration: TimeInterval, for item: AudioPlayerItem) {
    }
    
    func audioPlayer(_ audioPlayer: AudioPlayer, didUpdateEmptyMetadataOn item: AudioPlayerItem, withData data: Metadata) {
    }
    
    func audioPlayer(_ audioPlayer: AudioPlayer, didLoad range: TimeRange, for item: AudioPlayerItem) {
    }

    @IBAction func downloadAudio(_ sender: UIButton) {
        if let item = item {
            if item.isDownloaded {
                SPAlert.present(message: "Файл уже загружен", haptic: .warning)
            } else {
                SPAlert.present(message: "Файл загружается", haptic: .none)
                
                do {
                    try item.downloadAudio()
                } catch {
                    showEventMessage(.error, message: "Невозможно загрузить файл")
                }
            }
        }
    }

    @IBAction func didSetRepeatMode(_ sender: UIButton) {
        guard let audioPlayer = AudioService.instance.player else { return }
        let currentMode = audioPlayer.mode
        let isShuffle = audioPlayer.mode == .shuffle
        
        if currentMode != .repeat && currentMode != .repeatAll {
            audioPlayer.mode = isShuffle ? [.shuffle, .repeatAll] : [.repeatAll]
            sender.alpha = 1
            sender.setImage(.init(named: "repeat_24")?.tint(with: .white), for: .normal)
        }
        
        if currentMode == .repeatAll {
            audioPlayer.mode = isShuffle ? [.shuffle, .repeat] : [.repeat]
            sender.alpha = 1
            sender.setImage(.init(named: "repeat_one_24")?.tint(with: .white), for: .normal)
        }
        
        if currentMode == .repeat {
            audioPlayer.mode = isShuffle ? [.shuffle] : [.normal]
            sender.alpha = 0.5
            sender.setImage(.init(named: "repeat_24")?.tint(with: .white), for: .normal)
        }
    }

    @IBAction func didSetSuffleMode(_ sender: UIButton) {
        guard let audioPlayer = AudioService.instance.player else { return }
        let currentMode = audioPlayer.mode
        let isRepeatAll = audioPlayer.mode == .repeatAll
        let isRepeatOne = audioPlayer.mode == .repeat
        
        if currentMode != .shuffle {
            audioPlayer.mode = !isRepeatAll ? (isRepeatOne ? [.repeat, .shuffle] : [.shuffle]) : [.repeatAll, .shuffle]
            sender.alpha = 1
        }
        
        if currentMode == .shuffle {
            audioPlayer.mode = !isRepeatAll ? (isRepeatOne ? [.repeat, .normal] : [.normal]) : [.repeatAll, .normal]
            sender.alpha = 0.5
        }
    }
}

extension BetaPlayerViewController: PlayerSliderProtocol {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        startConfigurePlayer()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let item = item {
            configure(withItem: item)
        }
    }
    
    func startConfigurePlayer() {
        NotificationCenter.default.addObserver(self, selector: #selector(onItemEdited(_:)), name: NSNotification.Name("AudioDownloaded"), object: nil)

        AudioService.instance.player?.thirdDelegate = self
        setVolumeButtonListener()
        
        progressView.delegate = self
        
        artworkBackdropImageView.image = .init(named: "missing_song_artwork_generic_proxy")?.applyDarkEffect()
        artworkImageView.image = .init(named: "missing_song_artwork_generic_proxy")
        artworkImageView.drawBorder(18, width: 0)
        
        repeatButton.setTitle("", for: .normal)
        shuffleButton.setTitle("", for: .normal)
        
        shuffleButton.setImage(.init(named: "shuffle_24")?.tint(with: .white), for: .normal)
        
        if let audioPlayer = AudioService.instance.player {
            let mode = audioPlayer.mode
            
            if mode == .normal {
                repeatButton.alpha = 0.5
                shuffleButton.alpha = 0.5
            }
            
            if mode == .repeatAll {
                repeatButton.alpha = 0.75
                repeatButton.setImage(.init(named: "repeat_one_24")?.tint(with: .white), for: .normal)
            }
            
            if mode == .repeatAll {
                repeatButton.alpha = 1
                repeatButton.setImage(.init(named: "repeat_24")?.tint(with: .white), for: .normal)
            }
            
            if mode == .shuffle {
                shuffleButton.alpha = 1
            }
        }
        
        moreButton.setTitle("", for: .normal)
        moreButton.drawBorder(18, width: 0)
        moreButton.backgroundColor = .white.withAlphaComponent(0.5)
        moreButton.setImage(.init(named: "more-horizontal")?.tint(with: .white), for: .normal)
        
        previousImage.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(previousTrack(_:))))
        playImage.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(playOrResume(_:))))
        nextImage.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(nextTrack(_:))))
        
        playImage.drawBorder(32, width: 0)
        
        timeElapsedLabel.text = Settings.lastPlayingTime.stringDuration
        timeElapsedLabel.sizeToFit()
        durationLabel.text = (Settings.lastPlayingTime - TimeInterval(item?.duration ?? 0)).stringDuration.replacingOccurrences(of: ":-", with: ":")
        durationLabel.sizeToFit()
       
        progressView.progress = Settings.lastProgress
        
        artistLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(searchArtist(_:))))
        artistLabel.textColor = .getAccentColor(fromType: .common)
    }
    
    func configure(withItem item: AudioPlayerItem) {
        titleLabel.attributedText = NSAttributedString(string: item.title ?? "", attributes: [.font: UIFont.systemFont(ofSize: 20, weight: .semibold), .foregroundColor: UIColor.white]) + NSAttributedString(string: " ") + NSAttributedString(string: item.subtitle ?? "", attributes: [.font: UIFont.systemFont(ofSize: 20, weight: .semibold), .foregroundColor: UIColor.white.withAlphaComponent(0.5)])
        artistLabel.text = item.artist
        
        progressView.duration = TimeInterval(item.duration?.doubleValue ?? 0)
        if let url = URL(string: item.albumThumb600) {
            KingfisherManager.shared.retrieveImage(with: url, options: nil) { receivedSize, totalSize in
                print(receivedSize, totalSize)
            } completionHandler: { result in
                switch result {
                case .success(let value):
                    self.artworkImageView.image = value.image
                    self.artworkBackdropImageView.image = value.image.applyDarkEffect()
                    
                    let transition = CATransition()
                    transition.duration = 0.3
                    transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                    transition.type = .fade
                    
                    self.artworkBackdropImageView.layer.add(transition, forKey: nil)
                    self.artworkImageView.layer.add(transition, forKey: nil)
                case .failure(let error):
                    print(error)
                    break
                }
            }
        } else {
            self.artworkImageView.image = .init(named: "missing_song_artwork_generic_proxy")
            self.artworkBackdropImageView.image = .init(named: "missing_song_artwork_generic_proxy")?.applyDarkEffect()
            
            let transition = CATransition()
            transition.duration = 0.3
            transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            transition.type = .fade
            
            self.artworkImageView.layer.add(transition, forKey: nil)
            self.artworkBackdropImageView.layer.add(transition, forKey: nil)
        }
        
        if let audioPlayer = AudioService.instance.player {
            let mode = audioPlayer.mode
            
            if mode == .normal {
                repeatButton.alpha = 0.5
                shuffleButton.alpha = 0.5
            }
            
            if mode == .repeatAll {
                repeatButton.alpha = 0.75
                repeatButton.setImage(.init(named: "repeat_one_24")?.tint(with: .white), for: .normal)
            }
            
            if mode == .repeatAll {
                repeatButton.alpha = 1
                repeatButton.setImage(.init(named: "repeat_24")?.tint(with: .white), for: .normal)
            }
            
            if mode == .shuffle {
                shuffleButton.alpha = 1
            }
        }
    }
    
    func changePlayButton() {
        guard let player = AudioService.instance.player else { return }
        
        playImage.image = UIImage(named: player.currentItem?.isPlaying ?? false ? "pause-circle" : "play-circle")?.tint(with: .white)
        
        let transition = CATransition()
        transition.duration = 0.3
        transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        transition.type = .fade
        
        playImage.layer.add(transition, forKey: nil)
    }
    
    private func setVolumeButtonListener() {
        do {
            try audioSession.setActive(true)
        } catch {}
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
    
    @objc func searchArtist(_ sender: UITapGestureRecognizer) {
        vkTabBarController?.closePopup(animated: true) { [weak self] in
            self?.vkTabBarController?.selectedIndex = 2
            
            let navigationController = self?.vkTabBarController?.viewControllers?[2] as? VKMNavigationController
            let searchController = navigationController?.viewControllers[0] as? SearchAudioViewController
            
            searchController?.searchKeyword = self?.artistLabel.text ?? ""
            searchController?.searchController?.searchBar.text = self?.artistLabel.text
        }
    }
    
    @objc func playOrResume(_ recognizer: UITapGestureRecognizer) {
        guard let player = AudioService.instance.player else { return }
        guard let item = item else {
            return
        }
        let items = queueItems
        
        switch player.state {
        case .buffering:
            log("item buffering", type: .debug)
        case .playing:
            player.pause()
        case .paused:
            player.resume()
        case .stopped where Settings.lastPlayingTime == 0:
            player.play(items: items, startAtIndex: items.firstIndex(of: item) ?? 0)
        case .stopped where Settings.lastPlayingTime > 0:
            player.resume(items: items, startAtIndex: items.firstIndex(of: item) ?? 0)
        case .waitingForConnection:
            log("player wait connection", type: .warning)
        case .failed(let error):
            log(error.localizedDescription, type: .error)
        case .stopped:
            log("stopped", type: .warning)
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
    
    @objc func onItemEdited(_ notification: Notification) {
        DispatchQueue.main.async { [self] in
            showEventMessage(.success, message: "Файл загружен")
        }
    }
}

extension BetaPlayerViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        queueItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "VKAudioViewCell", for: indexPath) as? VKAudioViewCell else { return UITableViewCell() }
        guard queueItems.indices.contains(indexPath.row) else { return UITableViewCell() }
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
        60
    }
}

extension UIStackView {
    var state: SongDataState {
        get {
            return axis == .vertical ? .full : .mini
        } set {
            axis = newValue == .full ? .vertical : .horizontal
        }
    }
}

extension Array where Element == NSLayoutConstraint {
    func setIdentityConstant(_ constant: CGFloat) {
        for constraint in self {
            constraint.constant = constant
        }
    }
}

extension Array where Element == MarqueeLabel {
    func setIdentityAlignment(_ alignment: NSTextAlignment) {
        for label in self {
            label.textAlignment = alignment
        }
    }
}

extension UIView {
    func animateLayer<Value>(_ keyPath: WritableKeyPath<CALayer, Value>, to value:Value, duration: CFTimeInterval) {
        
        let keyString = NSExpression(forKeyPath: keyPath).keyPath
        let animation = CABasicAnimation(keyPath: keyString)
        animation.fromValue = self.layer[keyPath: keyPath]
        animation.toValue = value
        animation.duration = duration
        self.layer.add(animation, forKey: animation.keyPath)
        var thelayer = layer
        thelayer[keyPath: keyPath] = value
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

extension UIImage {
    func blurredImage(with context: CIContext, radius: CGFloat, atRect: CGRect) -> UIImage? {
        guard let ciImg = CIImage(image: self) else { return nil }

        let cropedCiImg = ciImg.cropped(to: atRect)
        let blur = CIFilter(name: "CIGaussianBlur")
        blur?.setValue(cropedCiImg, forKey: kCIInputImageKey)
        blur?.setValue(radius, forKey: kCIInputRadiusKey)
        
        if let ciImgWithBlurredRect = blur?.outputImage?.composited(over: ciImg),
           let outputImg = context.createCGImage(ciImgWithBlurredRect, from: ciImgWithBlurredRect.extent) {
            return UIImage(cgImage: outputImg)
        }
        return nil
    }
}

extension UIImage {
    func imageByMakingWhiteBackgroundTransparent() -> UIImage? {
        let image = UIImage(data: self.jpegData(compressionQuality: 1.0)!)!
        let rawImageRef: CGImage = image.cgImage!

        let colorMasking: [CGFloat] = [222, 255, 222, 255, 222, 255]
        UIGraphicsBeginImageContext(image.size);

        let maskedImageRef = rawImageRef.copy(maskingColorComponents: colorMasking)
        UIGraphicsGetCurrentContext()?.translateBy(x: 0.0,y: image.size.height)
        UIGraphicsGetCurrentContext()?.scaleBy(x: 1.0, y: -1.0)
        UIGraphicsGetCurrentContext()?.draw(maskedImageRef!, in: CGRect.init(x: 0, y: 0, width: image.size.width, height: image.size.height))
        let result = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return result
    }
}
