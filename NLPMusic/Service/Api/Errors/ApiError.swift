//
//  ApiError.swift
//  vkExtended
//
//  Created by Ярослав Стрельников on 09.11.2020.
//

import Foundation
import SwiftyJSON

/// Represents Error recieved from VK API. More info - https://vk.com/dev/errors
public struct ApiError: Equatable {
    /// Error code
    public let code: Int
    /// Error message
    public let message: String
    /// Parameters of sent request
    public internal(set) var requestParams = [String: String]()
    /// Other info about error
    public internal(set) var otherInfo = [String: String]()
    
    init?(_ json: JSON) {
        
        guard let errorCode = json["error"]["error_code"].int else {
            return nil
        }
        
        guard let errorMessage = json["error"]["error_msg"].string else {
            return nil
        }
        
        code = errorCode
        message = errorMessage
        requestParams = makeRequestParams(from: json)
        otherInfo = makeOtherInfo(from: json["error"].dictionaryValue)
    }
    
    init?(errorJSON: JSON) {
        guard let errorMessage = errorJSON["error_description"].string else {
            return nil
        }
        
        code = 0
        message = errorMessage
    }
    
    // Only for unit tests
    init(code: Int, otherInfo: [String: String] = [:]) {
        self.code = code
        self.message = ""
        self.requestParams = [:]
        self.otherInfo = otherInfo
    }
    
    var toVK: VKError {
        return .api(self)
    }
    
    private func makeRequestParams(from error: JSON) -> [String: String] {
        var paramsDict = [String: String]()
        
        if let paramsArray: [[String: JSON]] = error["error"]["request_params"].array?.compactMap({ $0.dictionaryValue }) {
            for param in paramsArray {
                if let key = param["key"]?.string, let value = param["value"]?.string {
                    paramsDict.updateValue(value, forKey: key)
                }
            }
        }
        
        return paramsDict
    }
    
    private func makeOtherInfo(from errorDict: [String: Any]) -> [String: String] {
        var infoDict = [String: String]()
        let ignoredKeys = ["error_code", "error_msg", "request_params"]
        
        for (key, value) in errorDict {
            if !ignoredKeys.contains(key), let stringValue = value as? String {
                infoDict.updateValue(stringValue, forKey: key)
            }
        }
        
        return infoDict
    }
    
    public static func == (lhs: ApiError, rhs: ApiError) -> Bool {
        return lhs.code == rhs.code
    }
}
