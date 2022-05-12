//
//  NLPPlayerViewController.swift
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
import Alamofire
import MaterialComponents

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

class NLPPlayerViewController: NLPBaseViewController, AudioPlayerDelegate {
    @IBOutlet weak var titleLabel: MarqueeLabel!
    @IBOutlet weak var artistLabel: MarqueeLabel!
    @IBOutlet weak var artworkBackdropImageView: UIImageView!
    @IBOutlet weak var progressView: PlayerSlider!
    @IBOutlet weak var artworkImageView: ShadowImageView!
    @IBOutlet weak var timeElapsedLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var previousImage: UIImageView!
    @IBOutlet weak var playImage: UIImageView!
    @IBOutlet weak var nextImage: UIImageView!
    @IBOutlet weak var repeatButton: UIButton!
    @IBOutlet weak var shuffleButton: UIButton!
    @IBOutlet weak var nextTrackLabel: UILabel!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var downloadButton: UIButton!
    
    @IBOutlet weak var currentListTableView: UITableView!
    @IBOutlet weak var listViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var chevronImageView: UIImageView!
    
    var beeingSeek = false
    var item: AudioPlayerItem? 
    var queueItems: [AudioPlayerItem] = [] {
        didSet {
            DispatchQueue.main.async {
                self.currentListTableView?.reloadData()
            }
        }
    }
    let audioSession = AVAudioSession.sharedInstance()
    var isListOpened: Bool = false {
        didSet {
            DispatchQueue.main.async { [self] in
                listViewTopConstraint.constant = isListOpened ? 12 : currentListTableView.bounds.height

                UIView.animate(withDuration: 0.3, delay: 0, options: [.allowUserInteraction, .beginFromCurrentState]) {
                    self.currentListTableView.alpha = self.isListOpened ? 1 : 0
                    self.artworkImageView.alpha = !self.isListOpened ? 1 : 0
                    self.titleLabel.alpha = !self.isListOpened ? 1 : 0
                    self.artistLabel.alpha = !self.isListOpened ? 1 : 0
                    self.timeElapsedLabel.alpha = !self.isListOpened ? 1 : 0
                    self.durationLabel.alpha = !self.isListOpened ? 1 : 0
                    self.playImage.alpha = !self.isListOpened ? 1 : 0
                    self.nextImage.alpha = !self.isListOpened ? 1 : 0
                    self.progressView.alpha = !self.isListOpened ? 1 : 0
                    self.previousImage.alpha = !self.isListOpened ? 1 : 0
                    self.chevronImageView.transform = self.isListOpened ? CGAffineTransform(rotationAngle: -.pi) : .identity
                    
                    if let audioPlayer = AudioService.instance.player {
                        let mode = audioPlayer.mode
                        
                        if mode == .normal {
                            self.repeatButton?.alpha = !self.isListOpened ? 0.5 : 0
                            self.shuffleButton?.alpha = !self.isListOpened ? 0.5 : 0
                        }
                        
                        if mode == .repeatAll {
                            self.repeatButton?.alpha = !self.isListOpened ? 0.75 : 0
                            self.repeatButton?.setImage(.init(named: "repeat_one_24")?.tint(with: .white), for: .normal)
                        }
                        
                        if mode == .repeatAll {
                            self.repeatButton?.alpha = !self.isListOpened ? 1 : 0
                            self.repeatButton?.setImage(.init(named: "repeat_24")?.tint(with: .white), for: .normal)
                        }
                        
                        if mode == .shuffle {
                            self.shuffleButton?.alpha = !self.isListOpened ? 1 : 0
                        }
                    }
                    
                    self.downloadButton.alpha = !self.isListOpened ? 1 : 0
            
                    self.addButton.alpha = !self.isListOpened ? self.audioViewController?.audioItems.first(where: { $0.id == self.item?.id }) == nil ? 1 : 0.5 : 0
                    
                    self.view.layoutIfNeeded()
                }
            }
        }
    }
    
    weak var vkTabBarController: NLPTabController?
    
    var _navigationController: NLPMNavigationController? {
        vkTabBarController?.viewControllers?.first as? NLPMNavigationController
    }
    var audioViewController: NLPAudioViewController? {
        _navigationController?.viewControllers.first as? NLPAudioViewController
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func getIndexPath(byItem item: AudioPlayerItem) -> IndexPath? {
        guard let index = queueItems.firstIndex(of: item) else { return nil }
        return IndexPath(row: index, section: 0)
    }
    
    override func didTap<T>(_ cell: NLPBaseViewCell<T>) {
        super.didTap(cell)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [self] in
            guard let indexPath = currentListTableView.indexPath(for: cell), let player = AudioService.instance.player else { return }
            let selectedItem = queueItems[indexPath.row]
            
            switch player.state {
            case .buffering:
                log("item buffering", type: .debug)
            case .playing:
                if player.currentItem == selectedItem {
                    player.pause()
                } else {
                    player.play(items: queueItems, startAtIndex: indexPath.row)
                }
            case .paused:
                if player.currentItem == selectedItem {
                    player.resume()
                } else {
                    player.play(items: queueItems, startAtIndex: indexPath.row)
                }
            case .stopped:
                DispatchQueue.main.async { [self] in
                    player.play(items: queueItems, startAtIndex: indexPath.row)
                }
            case .waitingForConnection:
                log("player wait connection", type: .warning)
            case .failed(let error):
                log(error.localizedDescription, type: .error)
            }
        }
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
            
            queueItems = audioPlayer.queue?.queue ?? []
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

            progressView?.progress = percentageRead / 100
            timeElapsedLabel?.text = time.stringDuration
            timeElapsedLabel?.sizeToFit()
            durationLabel?.text = (time - Double(duration)).stringDuration.replacingOccurrences(of: ":-", with: ":")
            durationLabel?.sizeToFit()
        }
    }
    
    func audioPlayer(_ audioPlayer: AudioPlayer, didFindDuration duration: TimeInterval, for item: AudioPlayerItem) {
    }
    
    func audioPlayer(_ audioPlayer: AudioPlayer, didUpdateEmptyMetadataOn item: AudioPlayerItem, withData data: Metadata) {
    }
    
    func audioPlayer(_ audioPlayer: AudioPlayer, didLoad range: TimeRange, for item: AudioPlayerItem) {
    }
    
    func audioPlayer(_ audioPlayer: AudioPlayer, didChangeModeFrom from: AudioPlayerMode, to mode: AudioPlayerMode) {
        queueItems = audioPlayer.queue?.queue ?? []
    }
    
    @IBAction func placeholder(_ sender: Any) {
        SPAlert.present(message: .localized(.temporarilyUnavailable), haptic: .warning)
    }

    @IBAction func addAudio(_ sender: Any) {
        guard let item = item, audioViewController?.audioItems.first(where: { $0.id == item.id }) == nil else { return }
        
        var parametersAudio: Parameters = [
            "audio_id" : item.id,
            "owner_id" : item.ownerId
        ]
        
        do {
            try ApiV2.method(.addAudio, parameters: &parametersAudio, apiVersion: .defaultApiVersion).done { result in
                DispatchQueue.main.async {
                    self.audioViewController?.audioItems.insert(item, at: 0)
                    self.audioViewController?.tableView.insertRows(at: [IndexPath(row: 0, section: 1)], with: .left)
                    self.addButton?.alpha = 0.5
                }
                SPAlert.present(title: .localized(.added), preset: .done, haptic: .success)
            }.catch { error in
                DispatchQueue.main.async {
                    self.addButton?.alpha = 1
                }
                print("Произошла ошибка при добавлении")
            }
        } catch {
            DispatchQueue.main.async {
                self.addButton?.alpha = 1
            }
            print("Произошла ошибка при добавлении")
        }
    }
    
    @IBAction func downloadAudio(_ sender: UIButton) {
        if let item = item {
            if item.isDownloaded {
                SPAlert.present(message: .localized(.alreadyDownloaded), haptic: .warning)
            } else {
                SPAlert.present(message: .localized(.fileLoading), haptic: .none)

                do {
                    try item.downloadAudio()
                } catch {
                    showEventMessage(.error, message: .localized(.errorDownload))
                }
            }
        }
    }

    @IBAction func didSetRepeatMode(_ sender: UIButton) {
        guard let audioPlayer = AudioService.instance.player else { return }
        let currentMode = audioPlayer.mode
        let isShuffle = audioPlayer.mode == .shuffle
        
        if !currentMode.contains(.repeat) && !currentMode.contains(.repeatAll) {
            audioPlayer.mode = isShuffle ? [.shuffle, .repeatAll] : [.repeatAll]
            sender.alpha = 1
            sender.setImage(.init(named: "repeat_24")?.tint(with: .white), for: .normal)
        }
        
        if currentMode.contains(.repeatAll) {
            audioPlayer.mode = isShuffle ? [.shuffle, .repeat] : [.repeat]
            sender.alpha = 1
            sender.setImage(.init(named: "repeat_one_24")?.tint(with: .white), for: .normal)
        }
        
        if currentMode.contains(.repeat) {
            audioPlayer.mode = isShuffle ? [.shuffle] : [.normal]
            sender.alpha = 0.5
            sender.setImage(.init(named: "repeat_24")?.tint(with: .white), for: .normal)
        }
    }

    @IBAction func didOpenList(_ sender: Any) {
        isListOpened.toggle()
    }
    
    @IBAction func didSetSuffleMode(_ sender: UIButton) {
        guard let audioPlayer = AudioService.instance.player else { return }
        let currentMode = audioPlayer.mode
        let isRepeatAll = audioPlayer.mode == .repeatAll
        let isRepeatOne = audioPlayer.mode == .repeat
        
        if !currentMode.contains(.shuffle) {
            audioPlayer.mode = !isRepeatAll ? (isRepeatOne ? [.repeat, .shuffle] : [.shuffle]) : [.repeatAll, .shuffle]
            sender.alpha = 1
        }
        
        if currentMode.contains(.shuffle) {
            audioPlayer.mode = !isRepeatAll ? (isRepeatOne ? [.repeat, .normal] : [.normal]) : [.repeatAll, .normal]
            sender.alpha = 0.5
        }
    }
}

extension NLPPlayerViewController: PlayerSliderProtocol {
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
        NotificationCenter.default.addObserver(self, selector: #selector(didDownload(_:)), name: NSNotification.Name("didDownloadAudio"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onItemEdited(_:)), name: NSNotification.Name("didRemoveAudio"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(onPlayerChangeState(_:)), name: NSNotification.Name("didStartPlaying"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onPlayerChangeState(_:)), name: NSNotification.Name("didPausePlaying"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onPlayerChangeState(_:)), name: NSNotification.Name("didStopPlaying"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onPlayerChangeState(_:)), name: NSNotification.Name("didResumePlaying"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onPlayerChangeState(_:)), name: NSNotification.Name("didDownloadAudio"), object: nil)

        currentListTableView?.contentInset.top = 24
        currentListTableView?.register(.listCell(.audio), forCellReuseIdentifier: .listCell(.audio))
        currentListTableView?.separatorStyle = .none
        currentListTableView?.alwaysBounceVertical = true
        currentListTableView?.delegate = self
        currentListTableView?.dataSource = self
        
        listViewTopConstraint.constant = isListOpened ? 12 : currentListTableView?.bounds.height ?? 0

        AudioService.instance.player?.thirdDelegate = self
        setVolumeButtonListener()
        
        progressView?.delegate = self
        artworkBackdropImageView?.image = .init(named: "missing_song_artwork_generic_proxy")?.applyDarkEffect()
        
        artworkImageView?.image = .init(named: "missing_song_artwork_generic_proxy")
        artworkImageView.shadowAlpha = 0.5
        artworkImageView?.shadowRadiusOffSetPercentage = 3
        artworkImageView?.shadowOffSetByY = -72

        artworkImageView.imageView.isSkeletonable = true
        artworkImageView.imageView.showAnimatedGradientSkeleton()
        
        timeElapsedLabel.showAnimatedGradientSkeleton()
        timeElapsedLabel.startSkeletonAnimation()

        durationLabel.showAnimatedGradientSkeleton()
        durationLabel.startSkeletonAnimation()

        artistLabel.showAnimatedGradientSkeleton()
        artistLabel.startSkeletonAnimation()

        titleLabel.showAnimatedGradientSkeleton()
        titleLabel.startSkeletonAnimation()

        nextTrackLabel.showAnimatedGradientSkeleton()
        nextTrackLabel.startSkeletonAnimation()
        
        repeatButton?.setTitle("", for: .normal)
        shuffleButton?.setTitle("", for: .normal)
        addButton?.setTitle("", for: .normal)
        downloadButton?.setTitle("", for: .normal)
        
        shuffleButton?.setImage(.init(named: "shuffle_24")?.tint(with: .white), for: .normal)
        downloadButton?.setImage(.init(named: "download_outline_24")?.tint(with: .white), for: .normal)
        addButton?.setImage(.init(named: "add_outline_24")?.tint(with: .white), for: .normal)
        
        if let audioPlayer = AudioService.instance.player {
            let mode = audioPlayer.mode
            
            if mode == .normal {
                repeatButton?.alpha = 0.5
                shuffleButton?.alpha = 0.5
            }
            
            if mode == .repeatAll {
                repeatButton?.alpha = 0.75
                repeatButton?.setImage(.init(named: "repeat_one_24")?.tint(with: .white), for: .normal)
            }
            
            if mode == .repeatAll {
                repeatButton?.alpha = 1
                repeatButton?.setImage(.init(named: "repeat_24")?.tint(with: .white), for: .normal)
            }
            
            if mode == .shuffle {
                shuffleButton?.alpha = 1
            }
        }
        
        previousImage?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(previousTrack(_:))))
        playImage?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(playOrResume(_:))))
        nextImage?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(nextTrack(_:))))
        
        playImage?.drawBorder(32, width: 0)
        
        timeElapsedLabel?.text = Settings.lastPlayingTime.stringDuration
        timeElapsedLabel?.sizeToFit()
        durationLabel?.text = (Settings.lastPlayingTime - TimeInterval(item?.duration ?? 0)).stringDuration.replacingOccurrences(of: ":-", with: ":")
        durationLabel?.sizeToFit()
       
        progressView?.progress = Settings.lastProgress
        
        artistLabel?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(searchArtist(_:))))
        artistLabel?.textColor = .link
    }
    
    func configure(withItem item: AudioPlayerItem) {
        self.item = item
        view.subviews.forEach { $0.hideSkeleton() }
        titleLabel?.attributedText = NSAttributedString(string: item.title ?? "", attributes: [.font: UIFont.systemFont(ofSize: 20, weight: .semibold), .foregroundColor: UIColor.white]) + NSAttributedString(string: " ") + NSAttributedString(string: item.subtitle ?? "", attributes: [.font: UIFont.systemFont(ofSize: 20, weight: .semibold), .foregroundColor: UIColor.white.withAlphaComponent(0.5)])
        titleLabel?.sizeToFit()
        artistLabel?.text = item.artist
        artistLabel?.sizeToFit()
        
        if item.isDownloaded {
            downloadButton?.setImage(.init(named: "done_outline_24 @ check")?.tint(with: .white), for: .normal)
        } else {
            downloadButton?.setImage(.init(named: "download_outline_24")?.tint(with: .white), for: .normal)
        }
        
        addButton?.isEnabled = audioViewController?.audioItems.first(where: { $0.id == item.id }) == nil
        addButton?.alpha = audioViewController?.audioItems.first(where: { $0.id == item.id }) == nil ? 1 : 0.5
        
        progressView?.duration = TimeInterval(item.duration?.doubleValue ?? 0)
        if let url = URL(string: item.albumThumb600) {
            KingfisherManager.shared.retrieveImage(with: url, options: nil) { receivedSize, totalSize in
                print(receivedSize, totalSize)
            } completionHandler: { result in
                switch result {
                case .success(let value):
                    self.artworkImageView?.image = value.image
                    self.artworkBackdropImageView?.image = value.image.applyDarkEffect()
                    
                    let transition = CATransition()
                    transition.duration = 0.3
                    transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                    transition.type = .fade
                    
                    self.artworkBackdropImageView?.layer.add(transition, forKey: nil)
                    self.artworkImageView?.layer.add(transition, forKey: nil)
                case .failure(let error):
                    print(error)
                    break
                }
            }
        } else {
            self.artworkImageView?.image = .init(named: "missing_song_artwork_generic_proxy")
            self.artworkBackdropImageView?.image = .init(named: "missing_song_artwork_generic_proxy")?.applyDarkEffect()
            
            let transition = CATransition()
            transition.duration = 0.3
            transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            transition.type = .fade
            
            self.artworkImageView?.layer.add(transition, forKey: nil)
            self.artworkBackdropImageView?.layer.add(transition, forKey: nil)
        }
        
        if let audioPlayer = AudioService.instance.player, !isListOpened {
            let mode = audioPlayer.mode
            
            if mode == .normal {
                repeatButton?.alpha = 0.5
                shuffleButton?.alpha = 0.5
            }
            
            if mode == .repeatAll {
                repeatButton?.alpha = 0.75
                repeatButton?.setImage(.init(named: "repeat_one_24")?.tint(with: .white), for: .normal)
            }
            
            if mode == .repeatAll {
                repeatButton?.alpha = 1
                repeatButton?.setImage(.init(named: "repeat_24")?.tint(with: .white), for: .normal)
            }
            
            if mode == .shuffle {
                shuffleButton?.alpha = 1
            }
        }
    }
    
    func changePlayButton() {
        guard let player = AudioService.instance.player else { return }
        
        playImage?.image = UIImage(named: player.currentItem?.isPlaying ?? false ? "pause-circle" : "play-circle")?.tint(with: .white)
        
        let transition = CATransition()
        transition.duration = 0.3
        transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        transition.type = .fade
        
        playImage?.layer.add(transition, forKey: nil)
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
    
    @objc func didDownload(_ notification: Notification) {
        guard let item = notification.userInfo?["item"] as? AudioPlayerItem else { return }
        
        DispatchQueue.main.async { [self] in
            downloadButton?.setImage(.init(named: item.isDownloaded ? "done_outline_24 @ check" : "download_outline_24")?.tint(with: .white), for: .normal)
        }
    }
    
    @objc func searchArtist(_ sender: UITapGestureRecognizer) {
        guard item != nil else { return }
        vkTabBarController?.closePopup(animated: true) { [weak self] in
            self?.vkTabBarController?.selectedIndex = 2
            
            let navigationController = self?.vkTabBarController?.viewControllers?[2] as? NLPMNavigationController
            let searchController = navigationController?.viewControllers[0] as? NLPSearchAudioViewController
            
            searchController?.searchKeyword = self?.artistLabel?.text ?? ""
            searchController?.searchController?.searchBar.text = self?.artistLabel?.text
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
        guard notification.userInfo?["item"] is AudioPlayerItem else { return }
        
        DispatchQueue.main.async {
            self.currentListTableView?.reloadData()
        }
    }
    
    @objc func onPlayerChangeState(_ notification: Notification) {
        guard notification.userInfo?["item"] is AudioPlayerItem else { return }
        
        DispatchQueue.main.async {
            self.currentListTableView?.reloadData()
        }
    }
}

extension NLPPlayerViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        queueItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "NLPAudioViewCell", for: indexPath) as? NLPAudioViewCell else { return UITableViewCell() }
        guard queueItems.indices.contains(indexPath.row) else { return UITableViewCell() }
        cell.configure(with: queueItems[indexPath.row])
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear
        cell.nameLabel.textColor = .white
        cell.artistNameLabel.textColor = .white.withAlphaComponent(0.5)
        cell.delegate = self
        cell.trailingSecondConstraint.constant = -36
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
