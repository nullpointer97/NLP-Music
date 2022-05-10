//
//  UIView+Extensions.swift
//  vkExtended
//
//  Created by Ярослав Стрельников on 19.10.2020.
//

import Foundation
import UIKit

extension UIView {
    func prepareBackground() {
        backgroundColor = .getThemeableColor(fromNormalColor: .white)
    }
    // Добавление блюра к View
    func setBlurBackground(style: UIBlurEffect.Style, frame: CGRect = .zero, cornerRadius: CGFloat = 0) {
        let blurEffect = UIBlurEffect(style: style)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = frame == .zero ? bounds : frame
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurView.drawBorder(cornerRadius, width: 0)
        insertSubview(blurView, at: 0)
    }

    // Добавление блюра к View
    func blurry() {
        let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.light)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(blurView)
    }
    
    // Задать скругления
    func setCorners(radius: CGFloat) {
        layer.masksToBounds = true
        layer.cornerRadius = radius
    }
    
    // Задать скругления
    func setCorners(radius: CGFloat, isOnlyTopCorners: Bool = false, isOnlyBottomCorners: Bool = false, isAllCorners: Bool = true) {
        layer.masksToBounds = true
        layer.cornerRadius = radius
        if isAllCorners {
            layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        }
        if isOnlyTopCorners {
            layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        }
        if isOnlyBottomCorners {
            layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        }
    }
    
    // Сделать круглым
    func setRounded(with border: CGFloat = 0) {
        layer.masksToBounds = true
        layer.cornerRadius = bounds.size.height / 2
        if border > 0 {
            layer.shouldRasterize = false
            layer.rasterizationScale = 2
            layer.borderWidth = border
//            layer.borderColor = UIColor.adaptableDivider.cgColor
        }
    }
    
    // Сделать обводку
    func setBorder(_ radius: CGFloat, width: CGFloat, color: UIColor = UIColor.clear) {
        layer.masksToBounds = true
        layer.cornerRadius = CGFloat(radius)
        layer.shouldRasterize = false
        layer.rasterizationScale = 2
        layer.borderWidth = width
        layer.borderColor = color.cgColor
    }
    
    func drawBorder(_ radius: CGFloat, width: CGFloat, color: UIColor = UIColor.clear, isOnlyTopCorners: Bool = false, isAnimated: Bool = false) {
        layer.masksToBounds = true
        layer.cornerRadius = CGFloat(radius)
        layer.maskedCorners = isOnlyTopCorners ?
            [.layerMinXMinYCorner, .layerMaxXMinYCorner] :
            [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        layer.borderWidth = width
        layer.shouldRasterize = false
        layer.borderColor = color.cgColor
        clipsToBounds = true
        
        if isAnimated {
            UIView.animate(withDuration: 0.2, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction]) { [weak self] in
                self?.layoutIfNeeded()
                self?.superview?.layoutIfNeeded()
            }
        }
    }
    
    func addWrapper(from width: CGFloat = 2, colors: Set<UIColor> = [.getThemeableColor(fromNormalColor: .black), .getThemeableColor(fromNormalColor: .black)]) {
        let externalBorderLayer = CAGradientLayer()
        externalBorderLayer.frame = bounds
        externalBorderLayer.cornerRadius = externalBorderLayer.frame.height / 2
        externalBorderLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
        externalBorderLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
        externalBorderLayer.colors = colors.map { $0.cgColor }
        
        let shape = CAShapeLayer()
        shape.lineWidth = 8
        shape.path = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: [.topLeft, .bottomLeft, .topRight, .bottomRight], cornerRadii: CGSize(width: frame.size.height / 2, height: frame.size.height / 2)).cgPath
        shape.strokeColor = UIColor.getThemeableColor(fromNormalColor: .black).cgColor
        shape.fillColor = UIColor.clear.cgColor
        externalBorderLayer.mask = shape
        
        let internalBorderLayer = CALayer()
        internalBorderLayer.frame = CGRect(x: width, y: width, width: frame.size.width - (width * 2), height: frame.size.height - (width * 2))
        internalBorderLayer.borderColor = UIColor.getThemeableColor(fromNormalColor: .white).cgColor
        internalBorderLayer.borderWidth = width
        internalBorderLayer.cornerRadius = internalBorderLayer.frame.height / 2

        layer.addSublayer(externalBorderLayer)
        layer.addSublayer(internalBorderLayer)
    }
    
    func removeWrapper() {
        guard let layers = layer.sublayers, !layers.isEmpty else { return }
        _ = layers.compactMap { layer in
            layer.removeFromSuperlayer()
        }
    }
    
    var hasWrapper: Bool {
        return layer.sublayers?.count ?? 0 > 1
    }
    
    func add<T: UIView>(to view: T?) {
        guard let view = view else { return }
        view.addSubview(self)
    }
    
    var roundedSize: CGFloat {
        let round = bounds.size.height / 2
        return round
    }
    
    func dropShadow(color: UIColor, opacity: Float = 0.5, offSet: CGSize, radius: CGFloat = 1, cornerRadius: CGFloat, scale: Bool = true) {
        layer.masksToBounds = false
        layer.shadowColor = color.cgColor
        layer.shadowOpacity = opacity
        layer.shadowOffset = offSet
        layer.shadowRadius = radius
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius).cgPath
        layer.shouldRasterize = true
        layer.rasterizationScale = scale ? UIScreen.main.scale : 1
    }
    
    var parentViewController: UIViewController? {
        var parentResponder: UIResponder? = self
        while parentResponder != nil {
            parentResponder = parentResponder?.next
            if let viewController = parentResponder as? UIViewController {
                return viewController
            }
        }
        return nil
    }
    
    var asImage: UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image(actions: { rendererContext in
            layer.render(in: rendererContext.cgContext)
        })
    }
    
    func resignFirstResponder<T: UIView>(_ object: T) {
        UIView.performWithoutAnimation {
            object.resignFirstResponder()
        }
    }
    
    func becomeFirstResponder<T: UIView>(_ object: T) {
        UIView.performWithoutAnimation {
            object.becomeFirstResponder()
        }
    }
    
    func addConstraintsWithFormat(format: String, views: UIView...) {
        var viewsDictionary = [String: UIView]()
        for (index, view) in views.enumerated() {
            let key = "v\(index)"
            viewsDictionary[key] = view
            view.translatesAutoresizingMaskIntoConstraints = false
        }
        
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: format, options: NSLayoutConstraint.FormatOptions(), metrics: nil, views: viewsDictionary))
    }
    
    func animated<T: UIView>(_ object: T, animations: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.3, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction, .preferredFramesPerSecond60], animations: {
            if let animations = animations {
                animations()
            }
            object.layoutIfNeeded()
        })
    }
    
    func addSubviews(_ views: [UIView]) {
        _ = views.map { addSubview($0) }
    }
    
    public func setConstraintsToView(top: UIView? = nil, tConst: CGFloat = 0,
                                     bottom: UIView? = nil, bConst: CGFloat = 0,
                                     left: UIView? = nil, lConst: CGFloat = 0,
                                     right: UIView? = nil, rConst: CGFloat = 0) {
        guard let suView = self.superview else { return }
        // Set top constraints if the view is specified.
        if let top = top {
            suView.addConstraint(
                NSLayoutConstraint(item: self, attribute: .top,
                                   relatedBy: .equal,
                                   toItem: top, attribute: .top,
                                   multiplier: 1.0, constant: tConst)
            )
        }
        // Set bottom constraints if the view is specified.
        if let bottom = bottom {
            suView.addConstraint(
                NSLayoutConstraint(item: self, attribute: .bottom,
                                   relatedBy: .equal,
                                   toItem: bottom, attribute: .bottom,
                                   multiplier: 1.0, constant: bConst)
            )
        }
        // Set left constraints if the view is specified.
        if let left = left {
            suView.addConstraint(
                NSLayoutConstraint(item: self, attribute: .left,
                                   relatedBy: .equal,
                                   toItem: left, attribute: .left,
                                   multiplier: 1.0, constant: lConst)
            )
        }
        // Set right constraints if the view is specified.
        if let right = right {
            suView.addConstraint(
                NSLayoutConstraint(item: self, attribute: .right,
                                   relatedBy: .equal,
                                   toItem: right, attribute: .right,
                                   multiplier: 1.0, constant: rConst)
            )
        }
    }
    
    public func centerSubView(_ view: UIView) {
        self.addConstraints([
                                NSLayoutConstraint(item: view, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1.0, constant: 0.0),
                                NSLayoutConstraint(item: view, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1.0, constant: 0.0)]
        )
    }
}

internal extension UIView {
    func centerInSuperview() {
        guard let superview = self.superview else {
            return
        }
        translatesAutoresizingMaskIntoConstraints = false
        let constraints: [NSLayoutConstraint] = [
            centerXAnchor.constraint(equalTo: superview.centerXAnchor),
            centerYAnchor.constraint(equalTo: superview.centerYAnchor)
        ]
        NSLayoutConstraint.activate(constraints)
    }
    
    func constraint(equalTo size: CGSize) {
        guard superview != nil else { return }
        translatesAutoresizingMaskIntoConstraints = false
        let constraints: [NSLayoutConstraint] = [
            widthAnchor.constraint(equalToConstant: size.width),
            heightAnchor.constraint(equalToConstant: size.height)
        ]
        NSLayoutConstraint.activate(constraints)
        
    }

    @discardableResult
    func addConstraints(_ top: NSLayoutYAxisAnchor? = nil, left: NSLayoutXAxisAnchor? = nil, bottom: NSLayoutYAxisAnchor? = nil, right: NSLayoutXAxisAnchor? = nil, centerY: NSLayoutYAxisAnchor? = nil, centerX: NSLayoutXAxisAnchor? = nil, topConstant: CGFloat = 0, leftConstant: CGFloat = 0, bottomConstant: CGFloat = 0, rightConstant: CGFloat = 0, centerYConstant: CGFloat = 0, centerXConstant: CGFloat = 0, widthConstant: CGFloat = 0, heightConstant: CGFloat = 0) -> [NSLayoutConstraint] {
        
        if self.superview == nil {
            return []
        }
        translatesAutoresizingMaskIntoConstraints = false
        
        var constraints = [NSLayoutConstraint]()
        
        if let top = top {
            let constraint = topAnchor.constraint(equalTo: top, constant: topConstant)
            constraint.identifier = "top"
            constraints.append(constraint)
        }
        
        if let left = left {
            let constraint = leftAnchor.constraint(equalTo: left, constant: leftConstant)
            constraint.identifier = "left"
            constraints.append(constraint)
        }
        
        if let bottom = bottom {
            let constraint = bottomAnchor.constraint(equalTo: bottom, constant: -bottomConstant)
            constraint.identifier = "bottom"
            constraints.append(constraint)
        }
        
        if let right = right {
            let constraint = rightAnchor.constraint(equalTo: right, constant: -rightConstant)
            constraint.identifier = "right"
            constraints.append(constraint)
        }

        if let centerY = centerY {
            let constraint = centerYAnchor.constraint(equalTo: centerY, constant: centerYConstant)
            constraint.identifier = "centerY"
            constraints.append(constraint)
        }

        if let centerX = centerX {
            let constraint = centerXAnchor.constraint(equalTo: centerX, constant: centerXConstant)
            constraint.identifier = "centerX"
            constraints.append(constraint)
        }
        
        if widthConstant > 0 {
            let constraint = widthAnchor.constraint(equalToConstant: widthConstant)
            constraint.identifier = "width"
            constraints.append(constraint)
        }
        
        if heightConstant > 0 {
            let constraint = heightAnchor.constraint(equalToConstant: heightConstant)
            constraint.identifier = "height"
            constraints.append(constraint)
        }
        
        NSLayoutConstraint.activate(constraints)
        return constraints
    }
}

var screenHeight: CGFloat {
    get {
        return UIScreen.main.bounds.height
    }
}
var screenWidth: CGFloat {
    get {
        return UIScreen.main.bounds.width
    }
}
var toolbarHeight: CGFloat {
    get {
        return 56
    }
}
extension UIImageView {
    func addBadge<T: UIView>(_ type: T, with size: CGSize = .zero) {
        let view = type
        view.add(to: self)
        view.autoPinEdge(.bottom, to: .bottom, of: self)
        view.autoPinEdge(.trailing, to: .trailing, of: self)
        view.autoSetDimensions(to: size)
    }
}

import Foundation

private var kRainbowAssociatedKey = "kRainbowAssociatedKey"

public class Rainbow: NSObject {
    var navigationBar: UINavigationBar
    
    init(navigationBar: UINavigationBar) {
        self.navigationBar = navigationBar
        
        super.init()
    }
    
    var navigationView: UIView?
    fileprivate var statusBarView: UIView?
    
    public var backgroundColor: UIColor? {
        get {
            return navigationView?.backgroundColor
        }
        set {
            if navigationView == nil {
                navigationBar.setBackgroundImage(UIImage(), for: .default)
                navigationBar.shadowImage = UIImage()
                navigationView = UIView(frame: CGRect(x: 0, y: -UIApplication.shared.statusBarFrame.height, width: navigationBar.bounds.width, height: navigationBar.bounds.height + UIApplication.shared.statusBarFrame.height))
                navigationView?.isUserInteractionEnabled = false
                navigationView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                navigationBar.insertSubview(navigationView!, at: 0)
            }
            navigationView!.backgroundColor = newValue
        }
    }
    public var statusBarColor: UIColor? {
        get {
            return statusBarView?.backgroundColor
        }
        set {
            if statusBarView == nil {
                statusBarView = UIView(frame: CGRect(x: 0, y: -UIApplication.shared.statusBarFrame.height, width: navigationBar.bounds.width, height: UIApplication.shared.statusBarFrame.height))
                statusBarView?.isUserInteractionEnabled = false
                statusBarView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                if let navigationView = navigationView {
                    navigationBar.insertSubview(statusBarView!, aboveSubview: navigationView)
                } else {
                    navigationBar.insertSubview(statusBarView!, at: 0)
                }
            }
            statusBarView?.backgroundColor = newValue
        }
    }
    public func clear() {
        navigationBar.setBackgroundImage(nil, for: .default)
        navigationBar.shadowImage = nil
        
        navigationView?.removeFromSuperview()
        navigationView = nil
        
        statusBarView?.removeFromSuperview()
        statusBarView = nil
    }
}

extension UINavigationBar {
    public var rb: Rainbow {
        get {
            if let rainbow = objc_getAssociatedObject(self, &kRainbowAssociatedKey) as? Rainbow {
                return rainbow
            }
            let rainbow = Rainbow(navigationBar: self)
            objc_setAssociatedObject(self, &kRainbowAssociatedKey, rainbow, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return rainbow
        }
    }
}
