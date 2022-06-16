//
//  UIEdgeInsets.swift
//  vkExtended
//
//  Created by Ярослав Стрельников on 29.10.2020.
//

import Foundation
import UIKit

extension UIEdgeInsets {
    static func identity(_ value: CGFloat) -> UIEdgeInsets {
        return UIEdgeInsets(top: value, left: value, bottom: value, right: value)
    }
    
    static func identityInverted(_ value: CGFloat) -> UIEdgeInsets {
        return UIEdgeInsets(top: value, left: value, bottom: -value, right: -value)
    }
    
    static func custom(_ top: CGFloat, _ left: CGFloat, _ bottom: CGFloat, _ right: CGFloat) -> UIEdgeInsets {
        return UIEdgeInsets(top: top, left: left, bottom: bottom, right: right)
    }
    
    static func horizontal(_ value: CGFloat) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: value, bottom: 0, right: value)
    }
    
    static func vertical(_ value: CGFloat) -> UIEdgeInsets {
        return UIEdgeInsets(top: value, left: 0, bottom: value, right: 0)
    }
    
    static func top(_ value: CGFloat) -> UIEdgeInsets {
        return UIEdgeInsets(top: value, left: 0, bottom: 0, right: 0)
    }
    
    static func bottom(_ value: CGFloat) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: value, right: 0)
    }
    
    static func left(_ value: CGFloat) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: value, bottom: 0, right: 0)
    }
    
    static func right(_ value: CGFloat) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: value)
    }
}
