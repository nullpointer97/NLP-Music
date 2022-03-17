//
//  DispatchQueue+Extension.swift
//  vkExtended
//
//  Created by Ярослав Стрельников on 05.12.2020.
//

import Foundation
import UIKit

extension DispatchQueue {
    func async(after delay: TimeInterval, execute: @escaping () -> Void) {
        asyncAfter(deadline: .now() + delay, execute: execute)
    }
}
