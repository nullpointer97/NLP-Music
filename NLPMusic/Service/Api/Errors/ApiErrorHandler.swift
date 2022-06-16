//
//  File.swift
//  VKM
//
//  Created by Ярослав Стрельников on 30.03.2021.
//

import Foundation

public protocol ApiErrorHandler {
    func handle(error: ApiError, token: InvalidatableToken?) throws -> ApiErrorHandlerResult
}

public final class ApiErrorHandlerImpl: ApiErrorHandler {
    
    private let executor: ApiErrorExecutor
    
    init(executor: ApiErrorExecutor) {
        self.executor = executor
    }
    
    public func handle(error: ApiError, token: InvalidatableToken?) throws -> ApiErrorHandlerResult {
        switch error.code {
        case 3610:
            token?.deactivate()
            return .deactivateToken
        case 5:
            token?.invalidate()
            return .invalidateToken
        default:
            throw VKError.api(error)
        }
    }
}

public enum ApiErrorHandlerResult {
    case invalidateToken
    case deactivateToken
}
