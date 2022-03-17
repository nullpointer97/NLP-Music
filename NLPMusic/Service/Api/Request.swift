//
//  Request.swift
//  Api
//
//  Created by Ярослав Стрельников on 19.10.2020.
//

import Foundation
import PromiseKit
import SwiftyJSON

extension Data {
    func json(has response: Bool = true) -> JSON {
        return response ? JSON(self)["response"] : JSON(self)
    }
}

//enum Response {
//    case success(Data)
//    case error(VKError)
//
//    init(_ data: Data, hasEvent: Bool = false) {
//        do {
//            let json = try JSON(data: data)
//
//            if let apiError = ApiError(json) {
//                self = .error(.api(apiError))
//                return
//            }
//            if hasEvent {
//                let successData = try json.rawData()
//                self = successData.isEmpty ? .success(data) : .success(successData)
//            } else {
//                let successData = try json["response"].rawData()
//                self = successData.isEmpty ? .success(data) : .success(successData)
//            }
//        }
//        catch let error {
//            self = .error(.jsonNotParsed(error))
//            return
//        }
//    }
//}

enum ErrorType: String {
    case incorrectLoginPassword = "invalid_client"
    case capthca = "need_captcha"
    case needValidation = "need_validation"
}

enum AuthData {
    case sessionInfo(accessToken: String, userId: Int)
}

struct Request {
    static let session = VK.sessions.default
    
    /*static func dataRequest(method: String, parameters: Alamofire.Parameters, hasEventMethod: Bool = false) -> Promise<Response> {
        let requestGroup =  DispatchGroup()
        requestGroup.enter()
        
        let headers = ["User-Agent" : Constants.userAgent]
        
        let url = "https://api.vk.com/method/" + method
        guard let token = VK.sessions.default.accessToken?.token else { fatalError("User authorization failed: no access_token passed") }
        
        var parameters: Alamofire.Parameters = parameters
        let sortedKeys = Array(parameters.keys).sorted(by: <)
        
        var stringForMD5 = "/method/\(method)?"
        for key in sortedKeys {
            stringForMD5 = stringForMD5 + key + "=\(parameters[key] ?? "")&"
        }
        if stringForMD5.last! == "&" {
            stringForMD5.remove(at: stringForMD5.index(before: stringForMD5.endIndex))
        }
        stringForMD5 = stringForMD5 + Constants.clientSecret
        parameters["v"] = 5.93
        parameters["access_token"] = token
        parameters["sig"] = MD5.MD5(stringForMD5)
        
        return Promise { seal in
            Alamofire.request(url, method: .get, parameters: parameters, encoding: URLEncoding.default, headers: headers).response { (response) in
                if let error = response.error {
                    seal.reject(error)
                    requestGroup.leave()
                    requestGroup.notify(queue: DispatchQueue.main, execute: {
                        log("/messages.getLongPollServer", type: .error)
                    })
                } else if let data = response.data {
                    seal.fulfill(Response(data, hasEvent: hasEventMethod))
                    requestGroup.leave()
                    requestGroup.notify(queue: DispatchQueue.main, execute: {
                        log("/messages.getLongPollServer", type: .success)
                    })
                }
            }
        }
    }*/
}
