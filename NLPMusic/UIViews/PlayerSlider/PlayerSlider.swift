//
//  PlayerSlider.swift
//  Player
//
//  Created by Pavel Yevtukhov on 6/2/17.
//  Copyright © 2017 Applikey Solutions. All rights reserved.
//

import UIKit

class ViewWithXib: UIView {

    func initUI() {}
    
    private func xibSetup() {
        let view = loadViewFromNib()
        addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.autoPinEdge(.leading, to: .leading, of: self)
        view.autoPinEdge(.trailing, to: .trailing, of: self)
        view.autoSetDimension(.height, toSize: 32)
        view.autoAlignAxis(toSuperviewAxis: .horizontal)
        initUI()
    }
    
    private func loadViewFromNib() -> UIView {
        let thisName = String(describing: type(of: self))
        let view = Bundle(for: self.classForCoder).loadNibNamed(thisName, owner: self, options: nil)?.first as! UIView
        return view
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        xibSetup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        xibSetup()
    }

}

protocol PlayerSliderProtocol: AnyObject {
	func onValueChanged(progress: Float, timePast: TimeInterval)
}

class PlayerSlider: ViewWithXib {

    // MARK: Constants
    
    private let maximumUnitCount = 2
    private let sliderMinimumValue: Float = 0
    private let sliderMaximumValue: Float = 1.0
    
    // MARK: Properties
    
    var delegate: PlayerSliderProtocol?
    var duration: TimeInterval = TimeInterval() {
        didSet {
            updateProgress(progress)
        }
    }
    
    var progress: Float {
        set(newValue) {
            guard !isDragging else {
                return
            }
            updateProgress(newValue)
        }
        
        get {
            return _progress
        }
    }
    
    private var _progress: Float = 0
    private var isDragging = false
    
    // MARK: Outlets
    @IBOutlet private weak var sliderView: NLPPlayerSlider!
    @IBAction private func sliderValueDidChanged(_ sender: NLPPlayerSlider) {
        updateProgress(sliderView.value)
    }
    
    // MARK:
	private func updateProgress(_ progress: Float) {
		var actualValue = progress >= sliderMinimumValue ? progress: sliderMinimumValue
		actualValue = progress <= sliderMaximumValue ? actualValue: sliderMaximumValue
		
		_progress = actualValue
	
		sliderView.value = actualValue
	}

	override func initUI() {
		super.initUI()
        sliderView.maximumTrackTintColor = .label.withAlphaComponent(0.1)
        sliderView.minimumTrackTintColor = .label
        sliderView.addTarget(self, action: #selector (dragDidBegin), for: .touchDragInside)
        sliderView.addTarget(self, action: #selector (dragDidEnd), for: .touchUpInside)
        sliderView.addTarget(self, action: #selector (dragDidEnd), for: .touchUpOutside)
        sliderView.setThumbImage(NLPPlayerSlider.thumbImage(diameter: 10), for: .normal)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        sliderView.maximumTrackTintColor = .label.withAlphaComponent(0.1)
        sliderView.minimumTrackTintColor = .label
        sliderView.setThumbImage(NLPPlayerSlider.thumbImage(diameter: 10), for: .normal)
    }
    
    @objc private func dragDidBegin() {
        isDragging = true
        sliderView.setThumbImage(NLPPlayerSlider.thumbImage(diameter: 20), for: .normal)
    }
	
	@objc private func dragDidEnd() {
		isDragging = false
		notifyDelegate()
        sliderView.setThumbImage(NLPPlayerSlider.thumbImage(diameter: 10), for: .normal)
	}
	
	private func notifyDelegate() {
		let timePast = duration * Double(sliderView.value)
		delegate?.onValueChanged(progress: sliderView.value, timePast: timePast)
	}
}

class NLPPlayerSlider: UISlider {
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        sliderTapped(touch: touch)
        return true
    }

    @objc private func sliderTapped(touch: UITouch) {
        let point = touch.location(in: self)
        let percentage = Float(point.x / bounds.width)
        let delta = percentage * (maximumValue - minimumValue)
        let newValue = minimumValue + delta
        print("seek to new value: \(newValue)")
        setValue(newValue, animated: true)
        sendActions(for: [.valueChanged, .touchUpOutside])
    }
    
    static func thumbImage(diameter: CGFloat) -> UIImage? {
        let strokeWidth: CGFloat = 3
        let halfStrokeWidth = strokeWidth / 2
        let totalRect = CGRect(x: 0, y: 0, width: diameter, height: diameter)
        let strokeRect = CGRect(x: halfStrokeWidth, y: halfStrokeWidth, width: diameter - strokeWidth, height: diameter - strokeWidth)
        
        let renderer = UIGraphicsImageRenderer(size: totalRect.size)
        let image = renderer.image { context in
            context.cgContext.setFillColor(UIColor.label.cgColor)
            context.cgContext.setStrokeColor(UIColor.systemBackground.cgColor)
            context.cgContext.setLineWidth(strokeWidth)
            context.cgContext.strokeEllipse(in: strokeRect)
        }.borderedImage(withPadding: 2)
        
        return image
    }
}

extension UIImage {
    func borderedImage(withPadding padding: Int) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(CGSize(width: size.width + CGFloat(padding), height: size.height + CGFloat(padding)), false, UIScreen.main.scale)
        let context = UIGraphicsGetCurrentContext()
        draw(in: CGRect(x: CGFloat(padding / 2), y: CGFloat(padding / 2), width: size.width, height: size.height))

        // Add border
        let bezier = UIBezierPath()
        bezier.lineWidth = 4.0
        bezier.lineJoinStyle = .round
        bezier.addArc(withCenter: CGPoint(x: size.width / 2 + CGFloat(padding / 2), y: size.height / 2 + CGFloat(padding / 2)), radius: size.height / 2 + CGFloat(padding / 2) - 2, startAngle: 0, endAngle: .pi, clockwise: false)
        bezier.addArc(withCenter: CGPoint(x: size.width / 2 + CGFloat(padding / 2), y: size.height / 2 + CGFloat(padding / 2)), radius: size.height / 2 + CGFloat(padding / 2) - 2, startAngle: .pi, endAngle: 2 * .pi, clockwise: false)
        context?.setStrokeColor(UIColor.systemBackground.cgColor)
        bezier.stroke()
        context?.setFillColor(UIColor.label.cgColor)
        bezier.fill()

        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result
    }
}
