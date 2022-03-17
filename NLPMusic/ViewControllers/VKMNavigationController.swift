//
//  VKMNavigationController.swift
//  VKM
//
//  Created by Ярослав Стрельников on 11.04.2021.
//

import Foundation
import UIKit
import AsyncDisplayKit

open class VKMNavigationController: ASDKNavigationController, UINavigationControllerDelegate, UIGestureRecognizerDelegate {
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
        interactivePopGestureRecognizer?.isEnabled = false
        view.addGestureRecognizer(fullScreenPanGestureRecognizer)
        
        navigationItem.largeTitleDisplayMode = .always
        navigationBar.prefersLargeTitles = true
        navigationBar.sizeToFit()

        navigationBar.tintColor = .getAccentColor(fromType: .common)
        navigationBar.isTranslucent = true
    }
    
    public func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        fullScreenPanGestureRecognizer.isEnabled = viewControllers.count > 1
    }
    
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        viewControllers.count > 1
    }
}
