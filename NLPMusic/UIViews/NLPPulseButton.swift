//
//  NLPPulseButton.swift
//  NLPMusic
//
//  Created by Ярослав Стрельников on 05.05.2022.
//  Copyright © 2022 NP-Team. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable public class NLPPulseButton: UIControl {
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
