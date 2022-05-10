//
//  ViewController+Extension.swift
//  VK Extended
//
//  Created by Ярослав Стрельников on 19.10.2020.
//

import Foundation
import UIKit
import Lottie
import Kingfisher
import PureLayout
import AsyncDisplayKit
import MaterialComponents

public extension UIViewController {
    func extraRemoveNavationBarDivider() {
        navigationController?.navigationBar.subviews.forEach { subview in
            if let _barBackgroundClass = NSClassFromString("_UIBarBackground") {
                if subview.isKind(of: _barBackgroundClass) {
                    subview.subviews.forEach { _subview in
                        if let _barBackgroundShadowView = NSClassFromString("_UIBarBackgroundShadowView") {
                            if _subview.isKind(of: _barBackgroundShadowView) {
                                _subview.alpha = 0
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Настройка фона для контроллера
    func setupBackground(for views: UIView...) {
        _ = views.map { view in
            view.backgroundColor = .systemBackground
        }
    }
    
    // Послать уведомление
    func postNotification(name: NSNotification.Name, object: Any? = nil, userInfo: [AnyHashable : Any]? = nil) {
        NotificationCenter.default.post(name: name, object: object, userInfo: userInfo)
    }
    
    var main: DispatchQueue {
        return .main
    }
    
    func withAsdkNavigationController() -> NLPMNavigationController {
        return NLPMNavigationController(rootViewController: self)
    }
    
    func withNavigationController() -> NLPMNavigationController {
        return NLPMNavigationController(rootViewController: self)
    }
}

private let swizzling: (UIViewController.Type, Selector, Selector) -> Void = { forClass, originalSelector, swizzledSelector in
    if let originalMethod = class_getInstanceMethod(forClass, originalSelector), let swizzledMethod = class_getInstanceMethod(forClass, swizzledSelector) {
        let didAddMethod = class_addMethod(forClass, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))
        if didAddMethod {
            class_replaceMethod(forClass, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod))
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }
}

extension UIViewController {
    
    static func swizzle() {
        let originalSelector1 = #selector(viewDidLoad)
        let swizzledSelector1 = #selector(swizzled_viewDidLoad)
        swizzling(UIViewController.self, originalSelector1, swizzledSelector1)
    }
    
    @objc open func swizzled_viewDidLoad() {
        if let _ = navigationController {
            if #available(iOS 14.0, *) {
                navigationItem.backButtonDisplayMode = .minimal
            } else {
                navigationItem.backButtonTitle = ""
            }
        }
        swizzled_viewDidLoad()
    }
}

fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l > r
    default:
        return rhs < lhs
    }
}


// Послать уведомление
func postNotification(name: NSNotification.Name, object: Any? = nil, userInfo: [AnyHashable : Any]? = nil) {
    NotificationCenter.default.post(name: name, object: object, userInfo: userInfo)
}
