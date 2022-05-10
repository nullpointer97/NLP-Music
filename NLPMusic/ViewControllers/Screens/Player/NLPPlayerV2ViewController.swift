//
//  NLPPlayerV2ViewController.swift
//  NLPMusic
//
//  Created by Ярослав Стрельников on 27.04.2022.
//  Copyright © 2022 NP-Team. All rights reserved.
//

import UIKit
import MarqueeLabel
import Kingfisher
import SPAlert
import Alamofire
import MediaPlayer

class NLPPlayerV2ViewController: NLPBaseViewController, PlayerSliderProtocol {
    @IBOutlet weak var artworkImageView: ShadowImageView!
    
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var prevButton: UIButton!
    @IBOutlet weak var playButton: PlayButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var downloadButton: UIButton!
    
    @IBOutlet weak var repeatButton: UIButton!
    @IBOutlet weak var repostButton: UIButton!
    @IBOutlet weak var listButton: UIButton!
    @IBOutlet weak var shuffleButton: UIButton!
    
    @IBOutlet weak var titleLabel: MarqueeLabel!
    @IBOutlet weak var subtitleLabel: MarqueeLabel!
    
    @IBOutlet weak var firstDurationLabel: UILabel!
    @IBOutlet weak var secondDurationLabel: UILabel!
    @IBOutlet weak var progressSlider: PlayerSlider!
    
    let volumeControl = MPVolumeView(frame: CGRect(x: 0, y: 0, width: 120, height: 120))
    
    weak var vkTabBarController: NLPTabController?
    
    var _navigationController: NLPMNavigationController? {
        vkTabBarController?.viewControllers?.first as? NLPMNavigationController
    }
    var audioViewController: NLPAudioViewController? {
        _navigationController?.viewControllers.first as? NLPAudioViewController
    }
    
    var player: AudioPlayer? {
        return AudioService.instance.player
    }
    
    var item: AudioPlayerItem? {
        return AudioService.instance.player?.currentItem
    }
    
    var beeingSeek = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureObservers()
        configureUI()
        AudioService.instance.player?.firstDelegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        configureUI()
    }
    
    private func configureObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(didDownload(_:)), name: NSNotification.Name("didDownloadAudio"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didRemoved(_:)), name: NSNotification.Name("didRemoveAudio"), object: nil)
    }
    
    private func configureUI() {
        view.backgroundColor = .systemBackground
        progressSlider.delegate = self
        configureImageView()
        configureButtons()
        configureLabels()
    }
    
    private func configureImageView() {
        artworkImageView.shadowAlpha = 0.6
        artworkImageView.shadowOffSetByY = -85
        artworkImageView.shadowRadiusOffSetPercentage = 8
        artworkImageView.blurRadius = 7.8
        artworkImageView.showAnimatedGradientSkeleton()
        artworkImageView.isUserInteractionEnabled = true
        
        let panGestureRecognizer = PanDirectionGestureRecognizer(direction: .horizontal, target: self, action: #selector(didVolumeChange(_:)))
        panGestureRecognizer.cancelsTouchesInView = false
        artworkImageView.addGestureRecognizer(panGestureRecognizer)
    }
    
    private func configureButtons() {
        addButton.setImage(.init(named: "add_outline_24")?.resize(toWidth: 24)?.resize(toHeight: 24)?.tint(with: .secondaryLabel), for: .normal)
        prevButton.setImage(.init(named: "backward.fill")?.tint(with: .label), for: .normal)
        nextButton.setImage(.init(named: "forward.fill")?.tint(with: .label), for: .normal)
        downloadButton.setImage(.init(named: "download_outline_28")?.resize(toWidth: 24)?.resize(toHeight: 24)?.tint(with: .secondaryLabel), for: .normal)
        repeatButton.setImage(.init(named: "repeat_24")?.resize(toWidth: 24)?.resize(toHeight: 24)?.tint(with: .secondaryLabel), for: .normal)
        repostButton.setImage(.init(named: "repost_24")?.resize(toWidth: 24)?.resize(toHeight: 24)?.tint(with: .secondaryLabel), for: .normal)
        listButton.setImage(.init(named: "playlist_24")?.resize(toWidth: 24)?.resize(toHeight: 24)?.tint(with: .secondaryLabel), for: .normal)
        shuffleButton.setImage(.init(named: "shuffle-2")?.resize(toWidth: 24)?.resize(toHeight: 24)?.tint(with: .secondaryLabel), for: .normal)
        
        playButton.backgroundColor = .label
        playButton.drawBorder(playButton.bounds.height / 2, width: 0)
        playButton.setMode(.buffering, animated: false)
        
        if let audioPlayer = player {
            let mode = audioPlayer.mode
            
            if mode == .normal {
                repeatButton?.alpha = 0.25
                shuffleButton?.alpha = 0.25
            }
            
            if mode == .repeatAll {
                repeatButton?.alpha = 0.75
                repeatButton?.setImage(.init(named: "repeat_one_24")?.tint(with: .secondaryLabel), for: .normal)
            }
            
            if mode == .repeatAll {
                repeatButton?.alpha = 1
                repeatButton?.setImage(.init(named: "repeat_24")?.tint(with: .secondaryLabel), for: .normal)
            }
            
            if mode == .shuffle {
                shuffleButton?.alpha = 1
            }
        }
    }
    
    private func configureLabels() {
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        subtitleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        secondDurationLabel.font = .systemFont(ofSize: 12, weight: .regular)
        firstDurationLabel.font = .systemFont(ofSize: 12, weight: .regular)
        
        titleLabel.textColor = .label
        subtitleLabel.textColor = .secondaryLabel
        secondDurationLabel.textColor = .secondaryLabel
        firstDurationLabel.textColor = .secondaryLabel
        
        titleLabel.showAnimatedGradientSkeleton()
        subtitleLabel.showAnimatedGradientSkeleton()
    }
    
    internal func onValueChanged(progress: Float, timePast: TimeInterval) {
        guard let player = player else {
            beeingSeek = false
            return
        }
        beeingSeek = true
        
        player.seek(to: timePast) { [weak self] _ in
            self?.beeingSeek = false
        }
    }
    
    @objc func didVolumeChange(_ gestureRecognizer: UIPanGestureRecognizer) {
        let lst = volumeControl.subviews.filter{NSStringFromClass($0.classForCoder) == "MPVolumeSlider"}
        let volumeSlider = lst.first as? UISlider
        
        let xTranslation = gestureRecognizer.translation(in: artworkImageView).x
        let tolerance: CGFloat = 2.25

        switch gestureRecognizer.state {
        case .began:
            let newValue = Float(xTranslation / tolerance)
            print(newValue)
        case .changed:
            if abs(xTranslation) >= tolerance {
                let newValue = Float(xTranslation / tolerance) / 100
                print(newValue)
                volumeSlider?.setValue(newValue, animated: true)
                // (MPVolumeView().subviews.filter{NSStringFromClass($0.classForCoder) == "MPVolumeSlider"}.first as? UISlider)?.setValue(1, animated: false)
            }
        case .ended:
            gestureRecognizer.setTranslation(.zero, in: artworkImageView)
        default:
            break
        }
    }
    
    @objc func didDownload(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            self?.downloadButton?.setImage(.init(named: "done_outline_24 @ check")?.tint(with: .secondaryLabel), for: .normal)
        }
    }
    
    @objc func didRemoved(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            self?.downloadButton?.setImage(.init(named: "download_outline_24")?.tint(with: .secondaryLabel), for: .normal)
        }
    }

    @IBAction func didTogglePlayButton(_ sender: UIButton) {
        player?.togglePlay()
    }
    
    @IBAction func didNextTrack(_ sender: UIButton) {
        player?.nextOrStop()
        
        let transition = CATransition()
        transition.duration = 0.3
        transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        transition.type = .reveal
        transition.subtype = .fromLeft
        
        sender.layer.add(transition, forKey: nil)
    }
    
    @IBAction func didPrevTrack(_ sender: UIButton) {
        player?.previous()
        
        let transition = CATransition()
        transition.duration = 0.3
        transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        transition.type = .reveal
        transition.subtype = .fromRight
        
        sender.layer.add(transition, forKey: nil)
    }

    @IBAction func didChangeRepeatMode(_ sender: UIButton) {
        guard let audioPlayer = player else { return }
        let currentMode = audioPlayer.mode
        let isShuffle = audioPlayer.mode == .shuffle
        
        if !currentMode.contains(.repeat) && !currentMode.contains(.repeatAll) {
            audioPlayer.mode = isShuffle ? [.shuffle, .repeatAll] : [.repeatAll]
            sender.alpha = 1
            sender.setImage(.init(named: "repeat_24")?.tint(with: .secondaryLabel), for: .normal)
        }
        
        if currentMode.contains(.repeatAll) {
            audioPlayer.mode = isShuffle ? [.shuffle, .repeat] : [.repeat]
            sender.alpha = 1
            sender.setImage(.init(named: "repeat_one_24")?.tint(with: .secondaryLabel), for: .normal)
        }
        
        if currentMode.contains(.repeat) {
            audioPlayer.mode = isShuffle ? [.shuffle] : [.normal]
            sender.alpha = 0.25
            sender.setImage(.init(named: "repeat_24")?.tint(with: .secondaryLabel), for: .normal)
        }
    }
    
    @IBAction func didChangeShuffleMode(_ sender: UIButton) {
        guard let audioPlayer = player else { return }
        let currentMode = audioPlayer.mode
        let isRepeatAll = audioPlayer.mode == .repeatAll
        let isRepeatOne = audioPlayer.mode == .repeat
        
        if !currentMode.contains(.shuffle) {
            audioPlayer.mode = !isRepeatAll ? (isRepeatOne ? [.repeat, .shuffle] : [.shuffle]) : [.repeatAll, .shuffle]
            sender.alpha = 1
        }
        
        if currentMode.contains(.shuffle) {
            audioPlayer.mode = !isRepeatAll ? (isRepeatOne ? [.repeat, .normal] : [.normal]) : [.repeatAll, .normal]
            sender.alpha = 0.25
        }
    }

    @IBAction func didStartDownload(_ sender: UIButton) {
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
    
    @IBAction func didOpenList(_ sender: UIButton) {
        let viewController = UIViewController()
        viewController.view.backgroundColor = .systemBackground.withAlphaComponent(0.1)
        viewController.view.setBlurBackground(style: .regular)
        present(viewController, animated: true)
    }

    @IBAction func didAddTrack(_ sender: UIButton) {
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
                    self.addButton?.alpha = 0.25
                }
                SPAlert.present(title: "Добавлено", preset: .done, haptic: .success)
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

    @IBAction func didShare(_ sender: UIButton) {
        let viewController = UIViewController()
        viewController.view.backgroundColor = .systemBackground.withAlphaComponent(0.1)
        viewController.view.setBlurBackground(style: .regular)
        present(viewController, animated: true)
    }
}

extension NLPPlayerV2ViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let gestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer else { return false }
        let velocity = gestureRecognizer.velocity(in: artworkImageView)
        return abs(velocity.x) > abs(velocity.y)
    }
}

extension NLPPlayerV2ViewController: AudioPlayerDelegate {
    func configurePlayer(from item: AudioPlayerItem) {
        if let url = item.albumThumb600 {
            downloadArtwork(with: url)
        } else {
            artworkImageView?.hideSkeleton()
            artworkImageView?.image = .init(named: "playlist_outline_56")
            
            let transition = CATransition()
            transition.duration = 0.3
            transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            transition.type = .fade
            
            artworkImageView?.layer.add(transition, forKey: nil)
        }
        
        titleLabel?.hideSkeleton()
        subtitleLabel?.hideSkeleton()
        
        titleLabel?.attributedText = NSAttributedString(string: item.title ?? "", attributes: [.font: UIFont.systemFont(ofSize: 20, weight: .semibold), .foregroundColor: UIColor.label]) + NSAttributedString(string: " ") + NSAttributedString(string: item.subtitle ?? "", attributes: [.font: UIFont.systemFont(ofSize: 20, weight: .semibold), .foregroundColor: UIColor.secondaryLabel])
        titleLabel?.sizeToFit()
        subtitleLabel?.text = item.artist
        subtitleLabel?.sizeToFit()
        
        if item.isDownloaded {
            downloadButton?.setImage(.init(named: "done_outline_24 @ check")?.tint(with: .secondaryLabel), for: .normal)
        } else {
            downloadButton?.setImage(.init(named: "download_outline_24")?.tint(with: .secondaryLabel), for: .normal)
        }
        
        addButton?.alpha = audioViewController?.audioItems.first(where: { $0.id == item.id }) == nil ? 1 : 0.25
        
        progressSlider?.duration = item.duration?.doubleValue ?? 0
        playButton.setMode(player?.state == .playing ? .pause : .play, animated: true)
    }
    
    func audioPlayer(_ audioPlayer: AudioPlayer, didChangeStateFrom from: AudioPlayerState, to state: AudioPlayerState) {
        switch state {
        case .buffering:
            playButton.setMode(.pause, animated: true)
            if playButton.mode != .buffering {
                playButton.setMode(.buffering, animated: true)
            }
        case .playing:
            playButton.setMode(.pause, animated: true)
        case .paused:
            playButton.setMode(.play, animated: true)
        case .stopped:
            playButton.setMode(.play, animated: true)
        case .waitingForConnection:
            playButton.setMode(.buffering, animated: true)
        case .failed(_):
            playButton.setMode(.stop, animated: true)
        }
    }
    
    func audioPlayer(_ audioPlayer: AudioPlayer, willStartPlaying item: AudioPlayerItem) {
        DispatchQueue.main.async { [weak self] in
            self?.configurePlayer(from: item)
        }
    }
    
    func audioPlayer(_ audioPlayer: AudioPlayer, willStopPlaying item: AudioPlayerItem) {
        DispatchQueue.main.async { [weak self] in
            self?.firstDurationLabel.text = "00:00"
            self?.secondDurationLabel.text = "00:00"
            self?.progressSlider.progress = 0
        }
    }
    
    func audioPlayer(_ audioPlayer: AudioPlayer, didUpdateProgressionTo time: TimeInterval, percentageRead: Float) {
        guard let duration = audioPlayer.currentItem?.duration, !beeingSeek else { return }
        
        progressSlider?.progress = percentageRead / 100
        firstDurationLabel?.text = time.stringDuration
        firstDurationLabel?.sizeToFit()
        secondDurationLabel?.text = (time - Double(duration)).stringDuration.replacingOccurrences(of: ":-", with: ":")
        secondDurationLabel?.sizeToFit()
    }
    
    private func downloadArtwork(with url: String?) {
        KingfisherManager.shared.retrieveImage(with: URL(string: url), options: nil) { receivedSize, totalSize in
            print(receivedSize, totalSize)
        } completionHandler: { result in
            switch result {
            case .success(let value):
                self.artworkImageView?.hideSkeleton()
                self.artworkImageView?.image = value.image
                
                let transition = CATransition()
                transition.duration = 0.3
                transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                transition.type = .fade
                
                self.artworkImageView?.layer.add(transition, forKey: nil)
            case .failure(let error):
                self.artworkImageView?.hideSkeleton()
                self.artworkImageView?.image = .init(named: "playlist_outline_56")
                
                let transition = CATransition()
                transition.duration = 0.3
                transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                transition.type = .fade
                
                self.artworkImageView?.layer.add(transition, forKey: nil)
            }
        }
    }
}

enum NLPPlaybackButtonState {
    case paused
    case playing
}

class NLPPlaybackButton: UIButton {
    var pathsView: AnimatePathsView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureAnimatableView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureAnimatableView()
    }
    
    private func configureAnimatableView() {
        pathsView = AnimatePathsView(frame: .init(x: 0, y: 0, width: 24, height: 24))
        pathsView.autoCenterInSuperview()
        pathsView.autoSetDimensions(to: .identity(24))
        setupAnimationPaths()
    }
    
    private func setupAnimationPaths() {
        //-----------------------------
        // Create a path that draws a pause symbol (two vertical bars) centered in the pathsView
        let pausePath =  CGMutablePath()
        let viewMiddleX = pathsView.bounds.midX
        let viewMiddleY = pathsView.bounds.midY
        let pauseBarSize = CGSize(width: 20, height: 90)
        let leftRectOrigin = CGPoint(x: viewMiddleX - pauseBarSize.width * 3 / 2, y: viewMiddleY - pauseBarSize.height / 2 )
        let leftBarRect = CGRect(origin: leftRectOrigin, size: pauseBarSize)
        let rightBarRect = leftBarRect.offsetBy(dx: pauseBarSize.width * 2, dy: 0)
        if true {
            // Create the left rectangle of the pause symbol. We do this by moving to the top left corner, then adding lines clockwise
            // for the remaining 3 points. Finally we call closeSubpath() to turn the rectangle into a closed path.
            // We could also create the 2 rectangles using the CGMutablePath method `addRect(_:transform:)` and the result would be the same.
            var leftBarRectCorners = leftBarRect.corners
            pausePath.move(to: leftBarRectCorners.removeFirst())
            while !leftBarRectCorners.isEmpty {
                pausePath.addLine(to: leftBarRectCorners.removeFirst())
            }
            pausePath.closeSubpath()
            
            // Create the right side rectangle of the pause symbol
            var rightBarRectCorners = rightBarRect.corners
            pausePath.move(to: rightBarRectCorners.removeFirst())
            while !rightBarRectCorners.isEmpty {
                pausePath.addLine(to: rightBarRectCorners.removeFirst())
            }
            pausePath.closeSubpath()
        } else {
            // This code would have exactly the same result as the code above that draws the rectangle one line segment at a time.
            pausePath.addRect(leftBarRect)
            pausePath.addRect(rightBarRect)
        }
        
        //--------------------------
        // Create a path that draws a play symbol triangle, but as 2 joined quadralaterals where the right quadralateral
        // has 2 of it's points at the same position so it is drawn in the shape of a triangle.
        let playPath =  CGMutablePath()
        let playPathHeight: CGFloat = 80.0
        let playPathWidth: CGFloat = 76.0
        
        // Create the left quadralateral as a trapezoid
        playPath.move(   to: CGPoint(x: viewMiddleX - playPathWidth / 2, y: viewMiddleY - playPathHeight / 2))
        playPath.addLine(to: CGPoint(x: viewMiddleX, y: viewMiddleY - playPathHeight / 4 ))
        playPath.addLine(to: CGPoint(x: viewMiddleX, y: viewMiddleY + playPathHeight / 4 ))
        playPath.addLine(to: CGPoint(x: viewMiddleX - playPathWidth / 2, y: viewMiddleY + playPathHeight / 2 ))
        playPath.closeSubpath()
        
        // Create the right quadralateral with it's right 2 points together, so it draws as a triangle.
        playPath.move(to: CGPoint(x: viewMiddleX, y: viewMiddleY - playPathHeight / 4 ))
        
        //The right 2 points are the same, turning the quadralateral into a triangle
        playPath.addLine(to: CGPoint(x: viewMiddleX + playPathWidth / 2, y: viewMiddleY))
        playPath.addLine(to: CGPoint(x: viewMiddleX + playPathWidth / 2, y: viewMiddleY))
        
        playPath.addLine(to: CGPoint(x: viewMiddleX, y: viewMiddleY + playPathHeight / 4))
        playPath.closeSubpath()
        
        pathsView.paths = [
            PathStep(path: pausePath),
            PathStep(path: playPath)
        ]
    }
    
    func toggleImage(playerState: AudioPlayerState) {
        pathsView.animate(repeats: false)
    }
}

class PlayPauseButton: UIControl {
    func setPlaying(_ playing: Bool) {
        self.playing = playing
        animateLayer()
    }
    
    private (set) var playing: Bool = false
    private let leftLayer: CAShapeLayer
    private let rightLayer: CAShapeLayer
    
    override init(frame: CGRect) {
        leftLayer = CAShapeLayer()
        rightLayer = CAShapeLayer()
        super.init(frame: frame)
        
        backgroundColor = UIColor.clear
        
        setupLayers()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("Not implemented")
    }
    
    private func setupLayers() {
        layer.addSublayer(leftLayer)
        layer.addSublayer(rightLayer)
        
        leftLayer.fillColor = UIColor.systemBackground.cgColor
        rightLayer.fillColor = UIColor.systemBackground.cgColor
        addTarget(self, action: #selector(pressed), for: .touchUpInside)
    }
    
    @objc private func pressed() {
        setPlaying(!playing)
    }
    
    private func animateLayer() {
        let fromLeftPath = leftLayer.path
        let toLeftPath = leftPath()
        leftLayer.path = toLeftPath
        
        let fromRightPath = rightLayer.path
        let toRightPath = rightPath()
        rightLayer.path = toRightPath
        
        let leftPathAnimation = pathAnimation(fromPath: fromLeftPath, toPath: toLeftPath)
        let rightPathAnimation = pathAnimation(fromPath: fromRightPath, toPath: toRightPath)
        
        leftLayer.add(leftPathAnimation, forKey: nil)
        rightLayer.add(rightPathAnimation, forKey: nil)
    }
    
    private func pathAnimation(fromPath: CGPath?, toPath: CGPath) -> CAAnimation {
        let animation = CABasicAnimation(keyPath: "path")
        animation.duration = 0.2
        animation.timingFunction = CAMediaTimingFunction(name: .easeIn)
        animation.fromValue = fromPath
        animation.toValue = toPath
        return animation
    }
    
    override func layoutSubviews() {
        leftLayer.frame = leftLayerFrame
        rightLayer.frame = rightLayerFrame

        leftLayer.path = leftPath()
        rightLayer.path = rightPath()
    }

    private let pauseButtonLineSpacing: CGFloat = 2

    private var leftLayerFrame: CGRect {
        return CGRect(x: 0, y: 0, width: bounds.width * 0.5, height: bounds.height)
    }

    private var rightLayerFrame: CGRect {
        return leftLayerFrame.offsetBy(dx: bounds.width * 0.5, dy: 0)
    }

    private func leftPath() -> CGPath {
        if playing {
            let bound = leftLayer.bounds.insetBy(dx: pauseButtonLineSpacing, dy: 0)
                .offsetBy(dx: -pauseButtonLineSpacing, dy: 0)

            return UIBezierPath(rect: bound).cgPath
        }

        return leftLayerPausedPath()
    }

    private func rightPath() -> CGPath {
        if playing {
            let bound = rightLayer.bounds.insetBy(dx: pauseButtonLineSpacing, dy: 0)
                .offsetBy(dx: pauseButtonLineSpacing, dy: 0)
            return UIBezierPath(rect: bound).cgPath
        }

        return rightLayerPausedPath()
    }

    private func leftLayerPausedPath() -> CGPath {
        let y1 = leftLayerFrame.width * 0.5
        let y2 = leftLayerFrame.height - leftLayerFrame.width * 0.5

        let path = UIBezierPath()
        path.move(to:CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: leftLayerFrame.width, y: y1))
        path.addLine(to: CGPoint(x: leftLayerFrame.width, y: y2))
        path.addLine(to: CGPoint(x: 0, y: leftLayerFrame.height))
        path.close()

        return path.cgPath
    }

    private func rightLayerPausedPath() -> CGPath {
        let y1 = rightLayerFrame.width * 0.5
        let y2 = rightLayerFrame.height - leftLayerFrame.width * 0.5
        let path = UIBezierPath()

        path.move(to:CGPoint(x: 0, y: y1))
        path.addLine(to: CGPoint(x: rightLayerFrame.width, y: rightLayerFrame.height * 0.5))
        path.addLine(to: CGPoint(x: rightLayerFrame.width, y: rightLayerFrame.height * 0.5))
        path.addLine(to: CGPoint(x: 0, y: y2))
        path.close()
        return path.cgPath
    }
}

extension KingfisherManager {
    @discardableResult
    public func retrieveImage(with resource: Resource?, options: KingfisherOptionsInfo? = nil, progressBlock: DownloadProgressBlock? = nil, downloadTaskUpdated: DownloadTaskUpdatedBlock? = nil, completionHandler: ((Swift.Result<RetrieveImageResult, KingfisherError>) -> Void)?) -> DownloadTask? {
        guard let resource = resource else {
            return nil
        }

        return retrieveImage(with: resource.convertToSource(), options: options, progressBlock: progressBlock, downloadTaskUpdated: downloadTaskUpdated, completionHandler: completionHandler)
    }
}

enum PanDirection {
    case vertical
    case horizontal
}

class PanDirectionGestureRecognizer: UIPanGestureRecognizer {

    let direction: PanDirection

    init(direction: PanDirection, target: AnyObject, action: Selector) {
        self.direction = direction
        super.init(target: target, action: action)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)

        if state == .began {
            let vel = velocity(in: view)
            switch direction {
            case .horizontal where abs(vel.y) > abs(vel.x):
                state = .cancelled
            case .vertical where abs(vel.x) > abs(vel.y):
                state = .cancelled
            default:
                break
            }
        }
    }
}
