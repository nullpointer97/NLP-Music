//
//  ApiV2.swift
//  VKM
//
//  Created by Ярослав Стрельников on 05.03.2021.
//

import Foundation
import Alamofire
import PromiseKit
import SwiftyJSON
import ObjectMapper

enum ApiMethodV2: String {
    case getAudio = "audio.get"
    case addAudio = "audio.add"
    case deleteAudio = "audio.delete"
    case getRecommendations = "audio.getRecommendations"
    case getPlaylists = "audio.getPlaylists"
    case deletePlaylist = "audio.deletePlaylist"
    case search = "audio.search"
    case musicPage = "execute.getMusicPage"
    case recommendationsOnboarding = "audio.recommendationsOnboarding"
    case finishRecomsOnboarding = "audio.finishRecomsOnboarding"
    case getRelatedArtistsById = "audio.getRelatedArtistsById"
    case getOnboardingOffer = "audio.getOnboardingOffer"
    case getFriends = "friends.get"
    case getUsers = "users.get"
}

struct ApiV2 {
    static private func configureParameters(method: String, _ parameters: inout Parameters, _ token: String, v: String = "5.131") -> Parameters {
        let sortedKeys = Array(parameters.keys).sorted(by: <)
        
        var md5String = "/method/\(method)?"
        for key in sortedKeys {
            md5String = md5String + key + "=\(parameters[key] ?? "")&"
        }
        if md5String.last! == "&" {
            md5String.remove(at: md5String.index(before: md5String.endIndex))
        }
        md5String = md5String + Constants.clientSecret
        
        print(md5String)
        
        parameters["lang"] = "ru"
        parameters["v"] = v
        parameters["access_token"] = token
        print(token)
        parameters["sig"] = MD5.MD5(md5String)

        return parameters
    }
    
    static func method(_ method: ApiMethodV2, parameters: inout Parameters, requestMethod: HTTPMethod = .get, apiVersion: String = "5.131", customToken: String = "") throws -> Promise<JSON> {
        guard let token = VK.sessions.default.accessToken?.token else { throw VKError.noAccessToken("Токен отсутствует, повторите авторизацию") }
        
        return firstly {
            Alamofire.request(apiUrl + method.rawValue, method: requestMethod, parameters: configureParameters(method: method.rawValue, &parameters, customToken.isEmpty ? token : customToken, v: apiVersion), encoding: URLEncoding.default, headers: userAgent).responseData(queue: .global(qos: .background))
        }.compactMap { response in
            if let apiError = ApiError(JSON(response.data)) {
                throw VKError.api(apiError)
            } else {
                let response = JSON(response.data)
                return response
            }
        }
    }
    
    static func method(_ method: String, parameters: inout Parameters, requestMethod: HTTPMethod = .get, apiVersion: String = "5.131", customToken: String = "") throws -> Promise<JSON> {
        guard let token = VK.sessions.default.accessToken?.token else { throw VKError.noAccessToken("Токен отсутствует, повторите авторизацию") }
        
        return firstly {
            Alamofire.request(apiUrl + method, method: requestMethod, parameters: configureParameters(method: method, &parameters, customToken.isEmpty ? token : customToken, v: apiVersion), encoding: URLEncoding.default, headers: userAgent).responseData(queue: .global(qos: .background))
        }.compactMap { response in
            if let apiError = ApiError(JSON(response.data)) {
                throw VKError.api(apiError)
            } else {
                let response = JSON(response.data)
                return response
            }
        }
    }
}

class OnlineResponse: Mappable {
    required init?(map: Map) { }
    
    func mapping(map: Map) {
        category <- map["category"]
    }
    
    var category: String!
}

public extension Data {

    /// SwifterSwift: String by encoding Data using the given encoding (if applicable).
    ///
    /// - Parameter encoding: encoding.
    /// - Returns: String by encoding Data using the given encoding (if applicable).
    func string(encoding: String.Encoding) -> String? {
        return String(data: self, encoding: encoding)
    }

    /// SwifterSwift: Returns a Foundation object from given JSON data.
    ///
    /// - Parameter options: Options for reading the JSON data and creating the Foundation object.
    ///
    ///   For possible values, see `JSONSerialization.ReadingOptions`.
    /// - Returns: A Foundation object from the JSON data in the receiver, or `nil` if an error occurs.
    /// - Throws: An `NSError` if the receiver does not represent a valid JSON object.
    func jsonObject(options: JSONSerialization.ReadingOptions = []) throws -> Any {
        return try JSONSerialization.jsonObject(with: self, options: options)
    }

}

extension String {
    static var defaultApiVersion = "5.90"
}
