//
//  KVolumeSlider.swift
//  vkmusic
//
//  Created by Ярослав Стрельников on 10.02.2022.
//  Copyright © 2022 NP-Team. All rights reserved.
//

import Foundation
import UIKit
import MediaPlayer
import AVFoundation

fileprivate class CustomProgressView: UIProgressView {
    
    var height:CGFloat = 1.0
    var weight:CGFloat = 10.0
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let size: CGSize = CGSize.init(width: weight, height: height)
        return size
    }
}

fileprivate enum Keys {
    static let AVAudioSessionOutputKey = "outputVolume"
}

class KVolumeSlider: UIView {
    
    private var session: AVAudioSession = AVAudioSession.sharedInstance()
    private var kWindow: UIWindow?
    private var volumeView: MPVolumeView = MPVolumeView(frame: CGRect.zero)
    private var progressView: CustomProgressView!
    private let screen = (UIScreen.main.bounds.size.width, UIScreen.main.bounds.size.height)
    private var hiddenBarCounter: Int = 0
    
    var backColor: UIColor = UIColor.gray.withAlphaComponent(0.3) {
        didSet {
            progressView.backgroundColor = backColor
        }
    }
    
    init() {
        let viewFrame = CGRect.init(x: 10, y: 10, width: screen.0 * 0.15, height: 5)
        super.init(frame: viewFrame)
        setupViews()
        setupAVSession()
        setupObservers()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupAVSession()
        setupObservers()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        backgroundColor = .clear

        if #available(iOS 13.0, *) {
            for scene in UIApplication.shared.connectedScenes {
                if scene == currentScene,
                   let delegate = scene.delegate as? SceneDelegate {
                    kWindow = delegate.window
                }
            }
        } else {
            kWindow = (UIApplication.shared.delegate as? AppDelegate)?.window
        }
        
        progressView = CustomProgressView(progressViewStyle: .bar)
        progressView.height = 7
        progressView.weight = self.frame.width
        progressView.layer.cornerRadius = round(progressView.height / 2)
        progressView.clipsToBounds = true
        progressView.frame = self.frame
        progressView.tintColor = UIColor.gray.withAlphaComponent(0.3)
        progressView.progress = session.outputVolume
        progressView.backgroundColor = backColor
        progressView.alpha = 0
        addSubview(progressView)
        
        volumeView.setVolumeThumbImage(UIImage(), for: UIControl.State())
        volumeView.isUserInteractionEnabled = false
        volumeView.alpha = 0.0001
        volumeView.showsRouteButton = false
        volumeView.backgroundColor = .clear
        addSubview(volumeView)
        
        session.addObserver(self, forKeyPath: Keys.AVAudioSessionOutputKey, options: .new, context: nil)
    }
    
    private func setupAVSession() {
        
        do {
            try session.setActive(true)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    private func setupObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillResignActive(notification:)), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive(notification:)), name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    private func showProgressView(_ val: Float) {
        
        if hiddenBarCounter == 0 {
            kWindow?.windowLevel = .statusBar + 1
        }
        
        hiddenBarCounter += 1
      
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseIn, .preferredFramesPerSecond60, .allowUserInteraction, .beginFromCurrentState], animations: {
            self.progressView.alpha = 1
            self.progressView.progress = val
        }, completion: { (finish) in
            UIView.animate(withDuration: 0.3, delay: 3, animations: {
                self.progressView.alpha = 0
            }, completion: { (finish) in
                self.hiddenBarCounter -= 1
                if self.hiddenBarCounter == 0 {
                    self.kWindow?.windowLevel = .normal
                }
            })
        })
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        guard let change = change, let value = change[.newKey] as? Float, keyPath == Keys.AVAudioSessionOutputKey else {
            return
        }
 
        showProgressView(value)
    }
    
    @objc func applicationWillResignActive(notification: Notification) {
        // session.removeObserver(self, forKeyPath: Keys.AVAudioSessionOutputKey, context: nil)
    }
    
    @objc func applicationDidBecomeActive(notification: Notification) {
        showProgressView(session.outputVolume)
        setupAVSession()
    }
    
    deinit {
        session.removeObserver(self, forKeyPath: Keys.AVAudioSessionOutputKey, context: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willResignActiveNotification, object: nil)
    }
}

class ProgressSlider: UISlider {
    @IBInspectable var trackHeight: CGFloat = 3
    @IBInspectable var thumbRadius: CGFloat = 20
    @IBInspectable var progress: Float = 0 {
        didSet {
            value = progress
        }
    }
    
    // Custom thumb view which will be converted to UIImage
    // and set as thumb. You can customize it's colors, border, etc.
    lazy var thumbView: UIView = {
        let thumb = UIView()
        thumb.backgroundColor = .white
        thumb.layer.borderWidth = 0.4
        thumb.layer.borderColor = UIColor.adaptableBorder.cgColor
        return thumb
    }()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let thumb = thumbImage(radius: thumbRadius)
        setThumbImage(thumb, for: .normal)
        setThumbImage(thumb, for: .highlighted)
    }
    
    private func thumbImage(radius: CGFloat) -> UIImage {
        // Set proper frame
        // y: radius / 2 will correctly offset the thumb
        
        thumbView.frame = CGRect(x: 0, y: radius / 2, width: radius, height: radius)
        thumbView.layer.cornerRadius = radius / 2
        
        // Convert thumbView to UIImage
        // See this: https://stackoverflow.com/a/41288197/7235585
        
        let renderer = UIGraphicsImageRenderer(bounds: thumbView.bounds)
        return renderer.image { rendererContext in
            thumbView.layer.render(in: rendererContext.cgContext)
        }
    }
    
    override func trackRect(forBounds bounds: CGRect) -> CGRect {
        // Set custom track height
        // As seen here: https://stackoverflow.com/a/49428606/7235585
        var newRect = super.trackRect(forBounds: bounds)
        newRect.size.height = trackHeight
        return newRect
    }
    
}
