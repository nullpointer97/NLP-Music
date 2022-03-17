//
//  OperationConvertible.swift
//  vkExtended
//
//  Created by Ярослав Стрельников on 30.10.2020.
//

import Foundation

public protocol OperationConvertible {
    func toOperation() -> Operation
    func cancel()
}

extension OperationConvertible where Self: Operation {
    func toOperation() -> Operation {
        return self
    }
}
