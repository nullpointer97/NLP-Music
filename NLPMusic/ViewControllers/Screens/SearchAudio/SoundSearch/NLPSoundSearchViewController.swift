//
//  NLPSoundSearchViewController.swift
//  NLPMusic
//
//  Created by Ярослав Стрельников on 13.04.2022.
//  Copyright © 2022 NP-Team. All rights reserved.
//

import UIKit
import MetalKit
import AVFoundation
import AudioUnit
import Accelerate
import ShazamKit
import QuartzCore

@IBDesignable public class CHPulseButton: UIControl {
    
    var pulseView = UIView()
    var button = UIButton()
    var imageView = UIImageView()
    
    public var isAnimate = false
    
    lazy private var pulseAnimation: CABasicAnimation = self.initAnimation()
    
    // MARK: Inspectable properties
    
    @IBInspectable public var contentImageScale: Int = 0 {
        didSet { imageView.contentMode = UIView.ContentMode(rawValue: contentImageScale)! }
    }
    
    @IBInspectable public var image: UIImage? {
        get { return imageView.image }
        set(image) { imageView.image = image }
    }
    
    @IBInspectable public var pulseMargin: CGFloat = 12.5
    
    @IBInspectable public var pulseBackgroundColor: UIColor = UIColor.lightGray {
        didSet { pulseView.backgroundColor = pulseBackgroundColor }
    }
    
    @IBInspectable public var buttonBackgroundColor: UIColor = UIColor.blue {
        didSet { button.backgroundColor = buttonBackgroundColor }
    }
    
    @IBInspectable public var titleColor: UIColor = UIColor.blue {
        didSet { button.setTitleColor(titleColor, for: .normal) }
    }
    
    @IBInspectable public var title: String? {
        didSet { button.setTitle(title, for: .normal) }
    }
    
    @IBInspectable public var pulsePercent: Float = 2
    @IBInspectable public var pulseAlpha: Float = 1.0 {
        didSet {
            pulseView.alpha = CGFloat(pulseAlpha)
        }
    }

    @IBInspectable public var circle: Bool = false
    
    @IBInspectable public var cornerRadius: CGFloat = 0.0 {
        didSet {
            if circle == true {
                cornerRadius = 0
            } else {
                button.layer.cornerRadius = cornerRadius - pulseMargin
                imageView.layer.cornerRadius = cornerRadius - pulseMargin
                pulseView.layer.cornerRadius = cornerRadius
            }
        }
    }
    
    // MARK: Initialization
    
    func initAnimation() -> CABasicAnimation {
        let anim = CABasicAnimation(keyPath: "transform.scale")
        anim.duration = 0.5
        anim.fromValue = 1
        anim.toValue = 1 * pulsePercent
        anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        anim.autoreverses = true
        anim.repeatCount = .greatestFiniteMagnitude
        return anim
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        setup()
        
        if circle {
            button.layer.cornerRadius = 0.5 * button.bounds.size.width
            pulseView.layer.cornerRadius = 0.5 * pulseView.bounds.size.width
            imageView.layer.cornerRadius = 0.5 * imageView.bounds.size.width

            button.clipsToBounds = true
            pulseView.clipsToBounds = true
            imageView.clipsToBounds = true
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    private func setup() {
        
        self.backgroundColor = UIColor.clear
        
        pulseView.frame = CGRect(x: 0, y: 0, width: bounds.size.width, height: bounds.size.height)
        addSubview(pulseView)
        
        button.frame = CGRect(x: pulseMargin / 2, y: pulseMargin / 2, width: bounds.size.width - pulseMargin, height: bounds.size.height - pulseMargin)
        addSubview(button)
        
        imageView.frame = CGRect(x: pulseMargin / 2, y: pulseMargin / 2, width: bounds.size.width - pulseMargin, height: bounds.size.height - pulseMargin)
        addSubview(imageView)
        
        for target in allTargets {
            let actions = actions(forTarget: target, forControlEvent: .touchUpInside)
            for action in actions! {
                button.addTarget(target, action:Selector(stringLiteral: action), for: .touchUpInside)
            }
        }
    }
    
    public func animate(start: Bool) {
        if start {
            self.pulseView.layer.add(pulseAnimation, forKey: nil)
        } else {
            self.pulseView.layer.removeAllAnimations()
        }
        isAnimate = start
    }
}

struct SoundRecord {
    var audioFilePathLocal: URL?
    var meteringLevels: [Float]?
}

@available(iOS 15.0, *)
class NLPSoundSearchViewController: NLPModalViewController {
    override var shortFormHeight: PanModalHeight {
        .contentHeight(236)
    }

    override var longFormHeight: PanModalHeight {
        .contentHeight(236)
    }
    
    override var dragIndicatorBackgroundColor: UIColor {
        .clear
    }
    
    weak var searchViewController: NLPSearchAudioViewController?
    var audioVisualizationView: AudioVisualizationView!
    var pulseButton: CHPulseButton!
    
    private(set) var isRecognizingSong = false
    private let session = SHSession()
    private let audioEngine = AVAudioEngine()
    private let feedback = UINotificationFeedbackGenerator()
    
    var audioVisualizationTimeInterval: TimeInterval = 0.05
    var currentAudioRecord: SoundRecord?
    private var isPlaying = false
    
    var audioMeteringLevelUpdate: ((Float) -> ())?
    var audioDidFinish: (() -> ())?
    
    var searchKeyword: String = ""
    
    private var chronometer: Chronometer?
    
    deinit {
        chronometer = nil
        try? AudioRecorderManager.shared.stopRecording()
        stopRecognition()
        _ = try? AVAudioSession.sharedInstance().setCategory(.playback)
        _ = try? AVAudioSession.sharedInstance().setActive(true)
        
        if AudioService.instance.player?.state == .paused {
            AudioService.instance.player?.resume()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        session.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveMeteringLevelUpdate), name: .audioPlayerManagerMeteringLevelDidUpdateNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveMeteringLevelUpdate), name: .audioRecorderManagerMeteringLevelDidUpdateNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(didFinishRecordOrPlayAudio), name: .audioPlayerManagerMeteringLevelDidFinishNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didFinishRecordOrPlayAudio), name: .audioRecorderManagerMeteringLevelDidFinishNotification, object: nil)
        
        audioVisualizationView = AudioVisualizationView(frame: .zero)
        view.addSubview(audioVisualizationView)
        audioVisualizationView.autoPinEdge(.top, to: .top, of: view, withOffset: 24)
        audioVisualizationView.autoPinEdge(.leading, to: .leading, of: view)
        audioVisualizationView.autoPinEdge(.trailing, to: .trailing, of: view)
        audioVisualizationView.autoSetDimension(.height, toSize: 100)
        
        audioVisualizationView.backgroundColor = .systemBackground
        audioVisualizationView.meteringLevelBarWidth = 2.5
        audioVisualizationView.meteringLevelBarInterItem = 1.0
        audioVisualizationView.meteringLevelBarCornerRadius = 1.75
        audioVisualizationView.meteringLevelBarSingleStick = true
        audioVisualizationView.audioVisualizationMode = .write
        audioVisualizationView.gradientStartColor = .getAccentColor(fromType: .common).withAlphaComponent(0.75)
        audioVisualizationView.gradientEndColor = .getAccentColor(fromType: .common).withAlphaComponent(0.75)
        
        pulseButton = CHPulseButton()
        pulseButton.title = ""
        pulseButton.add(to: view)
        pulseButton.autoPinEdge(.top, to: .bottom, of: audioVisualizationView, withOffset: 24)
        pulseButton.autoAlignAxis(toSuperviewAxis: .vertical)
        pulseButton.autoSetDimensions(to: .identity(64))
        pulseButton.buttonBackgroundColor = .getAccentColor(fromType: .common).withAlphaComponent(0.75)
        pulseButton.pulseBackgroundColor = .getAccentColor(fromType: .common).withAlphaComponent(0.35)
        pulseButton.circle = true
        
        pulseButton.addTarget(self, action: #selector(didConfigureRecord), for: .touchUpInside)
        
        audioMeteringLevelUpdate = { [weak self] meteringLevel in
            guard let self = self, self.audioVisualizationView.audioVisualizationMode == .write else {
                return
            }
            self.audioVisualizationView.add(meteringLevel: meteringLevel)
        }
    }
    
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        searchViewController?.isShazamed = true
        searchViewController?.searchKeyword = searchKeyword
        searchViewController?.searchController?.searchBar.text = searchKeyword
        
        pulseButton?.animate(start: false)
        stopRecording()
        
        super.dismiss(animated: true, completion: completion)
    }
    
    private func prepareAudioRecording() throws {
        let audioSession = AVAudioSession.sharedInstance()
        
        try audioSession.setCategory(.record)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    }
    
    // 2
    private func generateSignature() {
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: .zero)
        
        inputNode.installTap(onBus: .zero, bufferSize: 1024, format: recordingFormat) { [weak session] buffer, _ in
            session?.matchStreamingBuffer(buffer, at: nil)
        }
    }
    
    // 3
    private func startAudioRecording() throws {
        try audioEngine.start()
        
        isRecognizingSong = true
    }
    
    func startRecording(completion: @escaping (SoundRecord?, Error?) -> Void) {
        AudioRecorderManager.shared.startRecording(with: self.audioVisualizationTimeInterval, completion: { [weak self] url, error in
            guard let url = url else {
                completion(nil, error!)
                return
            }
            
            self?.currentAudioRecord = SoundRecord(audioFilePathLocal: url, meteringLevels: [])
            print("sound record created at url \(url.absoluteString))")
            completion(self?.currentAudioRecord, nil)
        })
        startRecognition()
    }
    
    func stopRecording() {
        try? AudioRecorderManager.shared.stopRecording()
        stopRecognition()
        _ = try? AVAudioSession.sharedInstance().setCategory(.playback)
        _ = try? AVAudioSession.sharedInstance().setActive(true)
    }
    
    public func startRecognition() {
        feedback.prepare()
        
        // 1
        do {
            if audioEngine.isRunning {
                stopRecognition()
                return
            }
            
            // 2
            try prepareAudioRecording()
            
            generateSignature()
            
            try startAudioRecording()
            
            feedback.notificationOccurred(.success)
        } catch {
            // Handle errors here
            print(error)
            feedback.notificationOccurred(.error)
        }
    }
    
    public func stopRecognition() {
        isRecognizingSong = false
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: .zero)
    }
    
    @objc private func didReceiveMeteringLevelUpdate(_ notification: Notification) {
        let percentage = notification.userInfo![audioPercentageUserInfoKey] as! Float
        self.audioMeteringLevelUpdate?(percentage)
    }
    
    @objc private func didFinishRecordOrPlayAudio(_ notification: Notification) {
        self.audioDidFinish?()
    }
    
    @objc func didConfigureRecord() {
        if !isRecognizingSong {
            pulseButton?.animate(start: true)
            
            AudioService.instance.player?.pause()
            
            startRecording { [weak self] soundRecord, error in
                if let error = error {
                    print(error)
                    return
                }

                self?.chronometer = Chronometer()
                self?.chronometer?.start()
            }
        } else {
            stopRecording()
            pulseButton?.animate(start: false)
            
            AudioService.instance.player?.resume()
        }
    }
}

@available(iOS 15.0, *)
extension NLPSoundSearchViewController: SHSessionDelegate {
    func session(_ session: SHSession, didFind match: SHMatch) {
        guard let mediaItem = match.mediaItems.first else { return }
        guard let title = mediaItem.title else { return }
        DispatchQueue.main.async {
            self.searchKeyword = "\(title) - \(mediaItem.artist ?? "")"
            self.dismiss(animated: true)
        }
    }
}

enum AudioErrorType: Error {
    case alreadyRecording
    case alreadyPlaying
    case notCurrentlyPlaying
    case audioFileWrongPath
    case recordFailed
    case playFailed
    case recordPermissionNotGranted
    case internalError
}

extension AudioErrorType: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .alreadyRecording:
            return "The application is currently recording sounds"
        case .alreadyPlaying:
            return "The application is already playing a sound"
        case .notCurrentlyPlaying:
            return "The application is not currently playing"
        case .audioFileWrongPath:
            return "Invalid path for audio file"
        case .recordFailed:
            return "Unable to record sound at the moment, please try again"
        case .playFailed:
            return "Unable to play sound at the moment, please try again"
        case .recordPermissionNotGranted:
            return "Unable to record sound because the permission has not been granted. This can be changed in your settings."
        case .internalError:
            return "An error occured while trying to process audio command, please try again"
        }
    }
}

let audioPercentageUserInfoKey = "percentage"

final class AudioRecorderManager: NSObject {
    let audioFileNamePrefix = "ru.npteam.nlpmusic"
    let encoderBitRate: Int = 320000
    let numberOfChannels: Int = 2
    let sampleRate: Double = 44100.0
    
    static let shared = AudioRecorderManager()
    
    var isPermissionGranted = false
    var isRunning: Bool {
        guard let recorder = self.recorder, recorder.isRecording else {
            return false
        }
        return true
    }
    
    var currentRecordPath: URL?
    
    private var recorder: AVAudioRecorder?
    private var audioMeteringLevelTimer: Timer?
    
    func askPermission(completion: ((Bool) -> Void)? = nil) {
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            self?.isPermissionGranted = granted
            completion?(granted)
        }
    }
    
    func startRecording(with audioVisualizationTimeInterval: TimeInterval = 0.05, completion: @escaping (URL?, Error?) -> Void) {
        func startRecordingReturn() {
            do {
                completion(try internalStartRecording(with: audioVisualizationTimeInterval), nil)
            } catch {
                completion(nil, error)
            }
        }
        
        if !self.isPermissionGranted {
            self.askPermission { granted in
                startRecordingReturn()
            }
        } else {
            startRecordingReturn()
        }
    }
    
    fileprivate func internalStartRecording(with audioVisualizationTimeInterval: TimeInterval) throws -> URL {
        if self.isRunning {
            throw AudioErrorType.alreadyPlaying
        }
        
        let recordSettings = [
            AVFormatIDKey: NSNumber(value:kAudioFormatAppleLossless),
            AVEncoderAudioQualityKey : AVAudioQuality.max.rawValue,
            AVEncoderBitRateKey : self.encoderBitRate,
            AVNumberOfChannelsKey: self.numberOfChannels,
            AVSampleRateKey : self.sampleRate
        ] as [String : Any]
        
        guard let path = URL.documentsPath(forFileName: UUID().uuidString + "_\(arc4random())") else {
            print("Incorrect path for new audio file")
            throw AudioErrorType.audioFileWrongPath
        }
        
//        try AVAudioSession.sharedInstance().setCategory(.record, mode: .default, options: .defaultToSpeaker)
//        try AVAudioSession.sharedInstance().setActive(true)
        
        try AVAudioSession.sharedInstance().setCategory(.record)
        try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
        
        self.recorder = try AVAudioRecorder(url: path, settings: recordSettings)
        self.recorder!.delegate = self
        self.recorder!.isMeteringEnabled = true
        
        if !self.recorder!.prepareToRecord() {
            print("Audio Recorder prepare failed")
            throw AudioErrorType.recordFailed
        }
        
        if !self.recorder!.record() {
            print("Audio Recorder start failed")
            throw AudioErrorType.recordFailed
        }
        
        self.audioMeteringLevelTimer = Timer.scheduledTimer(timeInterval: audioVisualizationTimeInterval, target: self, selector: #selector(AudioRecorderManager.timerDidUpdateMeter), userInfo: nil, repeats: true)
        
        print("Audio Recorder did start - creating file at index: \(path.absoluteString)")
        
        self.currentRecordPath = path
        return path
    }
    
    func stopRecording() throws {
        self.audioMeteringLevelTimer?.invalidate()
        self.audioMeteringLevelTimer = nil
        
        if !self.isRunning {
            print("Audio Recorder did fail to stop")
            throw AudioErrorType.notCurrentlyPlaying
        }
        
        self.recorder!.stop()
        print("Audio Recorder did stop successfully")
    }
    
    func reset() throws {
        if self.isRunning {
            print("Audio Recorder tried to remove recording before stopping it")
            throw AudioErrorType.alreadyRecording
        }
        
        self.recorder?.deleteRecording()
        self.recorder = nil
        self.currentRecordPath = nil
        
        print("Audio Recorder did remove current record successfully")
    }
    
    @objc func timerDidUpdateMeter() {
        if self.isRunning {
            self.recorder!.updateMeters()
            let averagePower = recorder!.averagePower(forChannel: 0)
            let percentage: Float = pow(4, (0.05 * averagePower))
            NotificationCenter.default.post(name: .audioRecorderManagerMeteringLevelDidUpdateNotification, object: self, userInfo: [audioPercentageUserInfoKey: percentage])
        }
    }
}

extension AudioRecorderManager: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        NotificationCenter.default.post(name: .audioRecorderManagerMeteringLevelDidFinishNotification, object: self)
        print("Audio Recorder finished successfully")
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        NotificationCenter.default.post(name: .audioRecorderManagerMeteringLevelDidFailNotification, object: self)
        print("Audio Recorder error")
    }
}

extension Notification.Name {
    static let audioRecorderManagerMeteringLevelDidUpdateNotification = Notification.Name("AudioRecorderManagerMeteringLevelDidUpdateNotification")
    static let audioRecorderManagerMeteringLevelDidFinishNotification = Notification.Name("AudioRecorderManagerMeteringLevelDidFinishNotification")
    static let audioRecorderManagerMeteringLevelDidFailNotification = Notification.Name("AudioRecorderManagerMeteringLevelDidFailNotification")
    static let audioPlayerManagerMeteringLevelDidUpdateNotification = Notification.Name("AudioPlayerManagerMeteringLevelDidUpdateNotification")
    static let audioPlayerManagerMeteringLevelDidFinishNotification = Notification.Name("AudioPlayerManagerMeteringLevelDidFinishNotification")
}

extension URL {
    static func checkPath(_ path: String) -> Bool {
        let isFileExist = FileManager.default.fileExists(atPath: path)
        return isFileExist
    }
    
    static func documentsPath(forFileName fileName: String) -> URL? {
        let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let writePath = URL(string: documents)!.appendingPathComponent(fileName)
        
        var directory: ObjCBool = ObjCBool(false)
        if FileManager.default.fileExists(atPath: documents, isDirectory:&directory) {
            return directory.boolValue ? writePath : nil
        }
        return nil
    }
}

extension UIViewController {
    func showAlert(with error: Error) {
        let alertController = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .cancel) { _ in
            alertController.dismiss(animated: true, completion: nil)
        })
        
        DispatchQueue.main.async {
            self.present(alertController, animated: true, completion: nil)
        }
    }
}

extension UIColor {
    static var mainBackgroundPurple: UIColor {
        return UIColor(red: 61.0 / 255.0, green: 28.0 / 255.0, blue: 105.0 / 255.0, alpha: 1.0)
    }
    
    static var audioVisualizationPurpleGradientStart: UIColor {
        return UIColor(red: 76.0 / 255.0, green: 62.0 / 255.0, blue: 127.0 / 255.0, alpha: 1.0)
    }
    
    static var audioVisualizationPurpleGradientEnd: UIColor {
        return UIColor(red: 133.0 / 255.0, green: 112.0 / 255.0, blue: 190.0 / 255.0, alpha: 1.0)
    }
    
    static var mainBackgroundGray: UIColor {
        return UIColor(red: 193.0 / 255.0, green: 188.0 / 255.0, blue: 167.0 / 255.0, alpha: 1.0)
    }
    
    static var audioVisualizationGrayGradientStart: UIColor {
        return UIColor(red: 130.0 / 255.0, green: 135.0 / 255.0, blue: 115.0 / 255.0, alpha: 1.0)
    }
    
    static var audioVisualizationGrayGradientEnd: UIColor {
        return UIColor(red: 83.0 / 255.0, green: 85.0 / 255.0, blue: 71.0 / 255.0, alpha: 1.0)
    }
}
