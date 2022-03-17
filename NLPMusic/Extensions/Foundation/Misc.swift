//
//  Misc.swift
//  VKM
//
//  Created by Ярослав Стрельников on 07.03.2021.
//

import Foundation

func async<T: DispatchQueue>(_ queue: T, with delay: TimeInterval = 0, block: @escaping() -> ()) {
    queue.asyncAfter(deadline: .now() + delay) {
        block()
    }
}

public enum PrintType: String {
    case debug = "🔵 DEBUG ➯"
    case error = "🔴 ERROR ➯"
    case warning = "🟡 WARNING ➯"
    case success = "🟢 SUCCESS ➯"
}

public func log(_ items: Any..., type: PrintType, _ callingFunctionName: String = #function, _ lineNumber: UInt = #line, _ fileName: String = #file, separator: String = " ", terminator: String = "\n") {
}
