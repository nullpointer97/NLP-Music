//
//  CGSize+Extension.swift
//  vkExtended
//
//  Created by Ярослав Стрельников on 26.10.2020.
//

import Foundation
import UIKit

extension CGSize {
    static func custom(_ width: CGFloat, _ height: CGFloat) -> CGSize {
        return CGSize(width: width, height: height)
    }
    
    static func identity(_ value: CGFloat) -> CGSize {
        return CGSize(width: value, height: value)
    }
}
