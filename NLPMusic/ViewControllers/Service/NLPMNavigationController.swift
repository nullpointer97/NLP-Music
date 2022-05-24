//
//  NLPMNavigationController.swift
//  NLP Music
//
//  Created by Ярослав Стрельников on 11.04.2021.
//

import Foundation
import UIKit

open class NLPMNavigationController: UINavigationController, UINavigationControllerDelegate, UIGestureRecognizerDelegate {
    public var panScrollable: UIScrollView? {
        return nil
    }
    
    public var longFormHeight: PanModalHeight {
        return (viewControllers.first as? PanModalPresentable)?.longFormHeight ?? .contentHeight(0)
    }
    
    public var shortFormHeight: PanModalHeight {
        return (viewControllers.first as? PanModalPresentable)?.shortFormHeight ?? .contentHeight(0)
    }
    
    public var cornerRadius: CGFloat {
        return (viewControllers.first as? PanModalPresentable)?.cornerRadius ?? 12
    }
    
    public var springDamping: CGFloat {
        return (viewControllers.first as? PanModalPresentable)?.springDamping ?? 1
    }
    
    public var dragIndicatorBackgroundColor: UIColor {
        return (viewControllers.first as? PanModalPresentable)?.dragIndicatorBackgroundColor ?? .clear
    }
    
    public var dragIndicatorOffset: CGFloat {
        return (viewControllers.first as? PanModalPresentable)?.dragIndicatorOffset ?? 0
    }
    
    var observables: [Observable] = []
    public lazy var fullScreenPanGestureRecognizer: UIPanGestureRecognizer = {
        let gestureRecognizer = UIPanGestureRecognizer()
        
        if let cachedInteractionController = value(forKey: "_cachedInteractionController") as? NSObject {
            let selector = Selector(("handleNavigationTransition:"))
            if cachedInteractionController.responds(to: selector) {
                gestureRecognizer.addTarget(cachedInteractionController, action: selector)
            }
        }
        gestureRecognizer.delegate = self
        return gestureRecognizer
    }()
    
    public override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
    }
    
    public override init(navigationBarClass: AnyClass?, toolbarClass: AnyClass?) {
        super.init(navigationBarClass: NLPNavigationBar.self, toolbarClass: nil)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        configure()
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
    }
    
    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    func configure() {
        additionalSafeAreaInsets.top = 12
//        interactivePopGestureRecognizer?.isEnabled = false
//        view.addGestureRecognizer(fullScreenPanGestureRecognizer)
        
        navigationItem.largeTitleDisplayMode = .never
        navigationBar.prefersLargeTitles = false
        navigationBar.sizeToFit()

        navigationBar.tintColor = .getAccentColor(fromType: .common)
        navigationBar.isTranslucent = true
        navigationBar.titleTextAttributes = [.font: UIFont.systemFont(ofSize: 18, weight: UIFont.Weight(0.35))]
    }
    
    public func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        fullScreenPanGestureRecognizer.isEnabled = viewControllers.count > 1
    }
    
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        viewControllers.count > 1
    }
}

class NLPNavigationBar: UINavigationBar {
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return CGSize(width: UIScreen.main.bounds.width, height: height)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        for subview in subviews {
            let stringFromClass = NSStringFromClass(subview.classForCoder)
            
            if stringFromClass.contains("UINavigationBarContentView") {
                subview.frame = CGRect(x: 0, y: -8, width: frame.width, height: height)
                subview.sizeToFit()
            }
        }
    }
    
    private func commonInit() {
        height = 72
    }
}

private var AssociatedObjectHandle: UInt8 = 0

extension NLPNavigationBar {
    
    var height: CGFloat {
        get {
            if let h = objc_getAssociatedObject(self, &AssociatedObjectHandle) as? CGFloat {
                return h
            }
            return 0
        }
        set {
            objc_setAssociatedObject(self, &AssociatedObjectHandle, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
