//
//  Error.swift
//  vkExtended
//
//  Created by Ярослав Стрельников on 09.11.2020.
//

import Foundation

enum SwiftMessagesError: Error {
    case cannotLoadViewFromNib(nibName: String)
    case noRootViewController
}

extension Error {
    func toVK() -> VKError {
        if let vkError = self as? VKError {
            return vkError
        }
        else if let apiError = self as? ApiError {
            return .api(apiError)
        }
        else {
            return .unknown(self)
        }
    }
}
