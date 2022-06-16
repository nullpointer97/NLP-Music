//
//  Authorizator.swift
//  vkExtended
//
//  Created by Ярослав Стрельников on 09.11.2020.
//

import Alamofire
import Foundation
import PromiseKit
import SwiftyJSON

protocol Authorizator: AnyObject {
    func getSavedToken(sessionId: String) -> InvalidatableToken?
    func authorize(login: String, password: String, sessionId: String, revoke: Bool) -> Promise<(Int, InvalidatableToken)>
    func authorize(login: String, password: String, sessionId: String, revoke: Bool, captchaSid: String?, captchaKey: String?) -> Promise<(Int, InvalidatableToken)>
    func authorize(login: String, password: String, sessionId: String, revoke: Bool, code: String?, forceSms: Int?) -> Promise<(Int, InvalidatableToken)>
    func authorize(userId: Int, token: String, sessionId: String) throws -> Promise<(Int, InvalidatableToken)>
    func reset(sessionId: String) -> InvalidatableToken?
}

final class AuthorizatorImpl: Authorizator {
    private let queue = DispatchQueue(label: "VKExtended.authorizatorQueue")
    private let directAuthUrl: String = "https://oauth.vk.com/token?"
    
    private let appId: String
    private var tokenStorage: TokenStorage
    private weak var tokenMaker: TokenMaker?
    private weak var delegate: ExtendedVKAuthorizatorDelegate?
    
    private(set) var vkAppToken: InvalidatableToken?
    private var requestTimeout: TimeInterval = 10
    
    init(appId: String, delegate: ExtendedVKAuthorizatorDelegate?, tokenStorage: TokenStorage, tokenMaker: TokenMaker) {
        self.appId = appId
        self.delegate = delegate
        self.tokenStorage = tokenStorage
        self.tokenMaker = tokenMaker
    }
    
    func authorize(login: String, password: String, sessionId: String, revoke: Bool) -> Promise<(Int, InvalidatableToken)> {
        defer { vkAppToken = nil }
        
        return queue.sync {
            self.auth(login: login, password: password, sessionId: sessionId)
        }
    }
    
    func authorize(login: String, password: String, sessionId: String, revoke: Bool, captchaSid: String?, captchaKey: String?) -> Promise<(Int, InvalidatableToken)> {
        defer { vkAppToken = nil }
        
        return queue.sync {
            self.auth(login: login, password: password, sessionId: sessionId, captchaSid: captchaSid, captchaKey: captchaKey)
        }
    }

    func authorize(login: String, password: String, sessionId: String, revoke: Bool, code: String?, forceSms: Int? = 0) -> Promise<(Int, InvalidatableToken)> {
        defer { vkAppToken = nil }
        
        return queue.sync {
            self.auth(login: login, password: password, sessionId: sessionId, code: code, forceSms: forceSms)
        }
    }
    
    func authorize(userId: Int, token: String, sessionId: String) throws -> Promise<(Int, InvalidatableToken)> {
        defer { vkAppToken = nil }
        
        return queue.sync {
            Promise { box in
                box.fulfill(try self.getToken(sessionId: sessionId, authData: AuthData.sessionInfo(accessToken: token, userId: userId)))
            }
        }
    }
    
    func getSavedToken(sessionId: String) -> InvalidatableToken? {
        return queue.sync {
            tokenStorage.getFor(sessionId: sessionId)
        }
    }
    
    func reset(sessionId: String) -> InvalidatableToken? {
        return queue.sync {
            tokenStorage.removeFor(sessionId: sessionId)
            return nil
        }
    }
    
    private func getToken(sessionId: String, authData: AuthData) throws -> (Int, InvalidatableToken) {
        switch authData {
        case .sessionInfo(accessToken: let accessToken, userId: let userId):
            let token = try makeToken(token: accessToken)
            try tokenStorage.save(token, for: sessionId)
            return (userId, token)
        }
    }

    private func makeToken(token: String) throws -> InvalidatableToken {
        guard let tokenMaker = tokenMaker else {
            throw VKError.weakObjectWasDeallocated
        }
        
        return tokenMaker.token(token: token)
    }
    
    private var settings: String {
        return "all"
    }
    
    func parameters(login: String, password: String) -> Alamofire.Parameters {
        let deviceId = UIDevice.current.identifierForVendor!.uuidString
        
        let parameters: Alamofire.Parameters = [
            "grant_type": "password",
            "client_id": Constants.appId,
            "client_secret": Constants.clientSecret,
            "username": login,
            "password": password,
            "v": "5.63",
            "scope": settings,
            "lang": "ru",
            "2fa_supported": 1,
            "device_id": deviceId
        ]
        return parameters
    }

    func auth(login: String, password: String, sessionId: String, captchaSid: String? = nil, captchaKey: String? = nil, code: String? = nil, forceSms: Int? = 0) -> Promise<(Int, InvalidatableToken)> {
        var alamofireParameters = parameters(login: login, password: password)
        
        if let captchaKey = captchaKey, let captchaSid = captchaSid {
            alamofireParameters["captcha_key"] = captchaKey
            alamofireParameters["captcha_sid"] = captchaSid
            
            print("auth:", alamofireParameters["captcha_key"])
            print("auth:", alamofireParameters["captcha_sid"])
        }

        if let code = code {
            alamofireParameters["code"] = code
        }
        
        if forceSms == 1 {
            alamofireParameters["force_sms"] = 1
        }
        
        let headers = [
            "User-Agent": Constants.userAgent
        ]
        
        return firstly {
            Alamofire.request(directAuthUrl, method: .get, parameters: alamofireParameters, headers: headers).responseJSON()
        }.compactMap {
            let error = $0["error"]
            if error != JSON.null {
                switch error.stringValue {
                case ErrorType.capthca.rawValue:
                    throw VKError.needCaptcha(captchaImg: $0["captcha_img"].stringValue, captchaSid: $0["captcha_sid"].stringValue)
                case ErrorType.incorrectLoginPassword.rawValue:
                    throw VKError.incorrectLoginPassword
                case ErrorType.needValidation.rawValue:
                    throw VKError.needValidation(validationType: $0["validation_type"].stringValue, phoneMask: $0["phone_mask"].stringValue, redirectUri: $0["redirect_uri"].string)
                default:
                    if let apiError = ApiError(errorJSON: $0) {
                        throw VKError.api(apiError)
                    } else {
                        throw VKError.authorizationFailed
                    }
                }
            } else {
                return try self.getToken(sessionId: sessionId, authData: AuthData.sessionInfo(accessToken: $0["access_token"].stringValue, userId: $0["user_id"].intValue))
            }
        }
    }
}

extension DataRequest {
    /// Adds a handler to be called once the request has finished.
    public func responseJSON(queue: DispatchQueue? = nil) -> Promise<JSON> {
        return Promise { seal in
            responseData(queue: queue) { response in
                switch response.result {
                case .success(let value):
                    seal.fulfill(JSON(value))
                case .failure(let error):
                    seal.reject(error)
                }
            }
        }
    }
    
//    public func responseData(queue: DispatchQueue? = nil) -> Promise<Data> {
//        return Promise { seal in
//            responseData(queue: queue) { response in
//                switch response.result {
//                case .success(let value):
//                    seal.fulfill(value)
//                case .failure(let error):
//                    seal.reject(error)
//                }
//            }
//        }
//    }
}
