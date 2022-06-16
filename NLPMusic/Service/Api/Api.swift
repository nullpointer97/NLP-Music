//
//  Api.swift
//  Extended Messenger
//
//  Created by Ярослав Стрельников on 16.01.2021.
//

import Foundation
import SwiftyJSON
import PromiseKit
import CoreStore

class Api {
    static func getParameters(method: String, _ parameters: inout [String: String], _ token: String, v: Double = 5.126)  {
        let sortedKeys = parameters.keys.sorted(by: <)
        
        var md5String = "/method/\(method)?"
        for key in sortedKeys {
            md5String = md5String + key + "=\(parameters[key] ?? "")&"
        }
        if md5String.last! == "&" {
            md5String.remove(at: md5String.index(before: md5String.endIndex))
        }
        md5String = md5String + Constants.clientSecret
        parameters["lang"] = "ru"
        parameters["v"] = "v"
        parameters["access_token"] = token
        parameters["sig"] = MD5.MD5(md5String)
    }
}
