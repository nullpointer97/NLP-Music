//
//  UIColorExtension.swift
//  TestASAlert
//
//  Created by Ali Samaiee on 8/9/21.
//

import Foundation
import UIKit

internal extension UIColor {
    static var asText = UIColor.label
    static var asAlertDivider = UIColor.adaptableBorder
    static var asAlertBackground = UIColor.systemBackground
    static var asCheckBoxBorder = UIColor(rgb: 0xD1D1D6)
    static var asRoundChecboxChekced = UIColor(red: 0.15, green: 0.68, blue: 0.38, alpha: 1.0)
    static var asTickColor = UIColor(rgb: 0x27AE60)
}

internal extension UIColor {
//    convenience init(rgb: UInt32) {
//        self.init(red: CGFloat((rgb >> 16) & 0xff) / 255.0, green: CGFloat((rgb >> 8) & 0xff) / 255.0, blue: CGFloat(rgb & 0xff) / 255.0, alpha: 1.0)
//    }
//    
//    convenience init(rgb: UInt32, alpha: CGFloat) {
//        self.init(red: CGFloat((rgb >> 16) & 0xff) / 255.0, green: CGFloat((rgb >> 8) & 0xff) / 255.0, blue: CGFloat(rgb & 0xff) / 255.0, alpha: alpha)
//    }
//    
//    convenience init(argb: UInt32) {
//        self.init(red: CGFloat((argb >> 16) & 0xff) / 255.0, green: CGFloat((argb >> 8) & 0xff) / 255.0, blue: CGFloat(argb & 0xff) / 255.0, alpha: CGFloat((argb >> 24) & 0xff) / 255.0)
//    }
}
