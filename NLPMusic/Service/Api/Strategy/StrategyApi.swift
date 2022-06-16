//
//  StrategyApi.swift
//  vkmusic
//
//  Created by Ярослав Стрельников on 02.02.2022.
//  Copyright © 2022 NP-Team. All rights reserved.
//

import Foundation

protocol BaseApiObject {
    var retryCount: Int { get set }
    var requestTimeout: Double? { get set }
}

enum HttpMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

protocol ApiService: AnyObject {
    func request<T>(with target: T, postCompleted : @escaping (_ response: T.ResultType) -> ()) where T: ApiResponseConvertible, T:ApiResponseErrorProcessor, T: ApiTarget
}

class StrategyApi: NSObject {
    typealias Async = ((Data?, URLResponse?, Error?) -> Void)

    var baseAddress: String
    
    var defaultTimeout: Double {
        return 10
    }
    
    var session: URLSession {
        let configuration = URLSessionConfiguration.default
        var headers: [AnyHashable: Any] = [:]
        headers["Content-Type"] = "text/html; charset=UTF-8"
        headers["content-length"] = "0"
        
        configuration.timeoutIntervalForRequest = defaultTimeout
        configuration.httpAdditionalHeaders = headers
        return URLSession.init(configuration: configuration)
    }
    
    init(baseAddress: String) {
        self.baseAddress = baseAddress
        super.init()
    }
    
    func request<T>(with target: T, postCompleted: @escaping (T.ResultType) -> ()) where T : ApiResponseConvertible, T : ApiResponseErrorProcessor, T : ApiTarget {
        do {
            let params = target.parameters
            guard let path = params[TargetParamNames.path.rawValue] else {
                throw "Internal framework error: \(TargetParamNames.path.rawValue) not specified"
            }
            guard let method = params[TargetParamNames.httpMethod.rawValue] else {
                throw "Internal framework error: \(TargetParamNames.httpMethod.rawValue) not specified"
            }
            
            guard var urlComponents = URLComponents(string: "\(baseAddress)") else {
                throw "Internal framework error: invalid base address"
            }
            
            urlComponents.path.append(path)
            
            var queryItems: [URLQueryItem] = []
            var headers: [String:String] = [:]

            for (key, value) in params {
                if key.hasPrefix("p.") {
                    queryItems.append(URLQueryItem(name: String(key.dropFirst("p.".count)), value: value))
                }
                if key.hasPrefix("h.") {
                    headers[String(key.dropFirst("h.".count))] = value
                }
            }
            
            if (queryItems.count > 0) {
                urlComponents.queryItems = queryItems
            }
            
            guard let url = urlComponents.url else {
                throw "Internal framework error: invalid URL"
            }
            
            print(url)
            
            var request = URLRequest(url: url)
            request.httpMethod = method

            var retries: Int
            if let retryCount = Int(params[TargetParamNames.retryCount.rawValue] ?? "0") {
                retries = retryCount
            } else {
                retries = 0
            }
            if let timeout = params[TargetParamNames.timeout.rawValue] {
                request.timeoutInterval = Double(timeout) ?? defaultTimeout
            } else {
                request.timeoutInterval = defaultTimeout
            }
            
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }

            if let body = params[TargetParamNames.body.rawValue] {
                request.httpBody = body.data(using: .utf8)
            }
            
            executeRequest(request, with: ApiRequestRetrier(retries: retries)) { data, response, error in
                var result: T.ResultType
                do {
                    if let data = data {
                        print(String(data: data, encoding: .utf8))
                        result = try target.convert(data: data)
                    } else if let error = error {
                        result = target.handleError(error: error)
                    } else {
                        if let response = response as? HTTPURLResponse {
                            let statusCode = response.statusCode
                            throw "Invalid response with status \"\(statusCode)\""
                        } else {
                            throw "Invalid response"
                        }
                    }
                } catch let errir as NSError {
                    do {
                        if let data = data {
                            let obj = try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
                            result = try target.convert(dictionary: obj)
                        } else {
                            result = target.handleError(error: errir)
                        }
                    } catch let err as NSError {
                        result = target.handleError(error: err)
                    }
                }
                postCompleted(result)
            }
        } catch {
            postCompleted(target.handleError(error: error))
        }
    }
    
    func executeRequest(_ request: URLRequest, with retrier: RequestRetrier?, postCompleted: @escaping (_ data: Data?, _ response: URLResponse?, _ error: Error?) -> () ) {
        executeRequest(request) { [weak self] data, response, error in
            if let retrier = retrier, retrier.isRetry(response: response, error: error) {
                self?.executeRequest(request, with: retrier, postCompleted: postCompleted)
            } else {
                postCompleted(data, response, error)
            }
        }
    }
    
    private func executeRequest(_ request: URLRequest, responseProcessor: @escaping Async) {
        let task = self.session.dataTask(with: request) { data, response, error in
            responseProcessor(data, response, error)
        }
        task.resume()
    }
}

protocol ApiTarget {
    var parameters: [String : String] { get }
}

protocol ApiResponseConvertible {
    associatedtype ResultType

    func convert(data: Data) throws -> ResultType
    func convert(dictionary: Any) throws -> ResultType
}

protocol ApiResponseErrorProcessor {
    associatedtype ResultType
    
    func handleError(error: Error) -> ResultType
}

protocol ApiStrategy {
    associatedtype ObjectType
    associatedtype ResultType

    static func target(with object: ObjectType) -> AnyTarget<ResultType>
}

struct AnyTarget<T>: ApiResponseConvertible, ApiTarget, ApiResponseErrorProcessor {
    
    private let _map: (Data) throws -> T
    private let _dictionary: (Any) throws -> T
    private let _handleError: (Error) -> T
    var parameters: [String : String]

    init<U>(with target: U) where U: ApiResponseConvertible, U: ApiTarget, U: ApiResponseErrorProcessor, U.ResultType == T {
        _map = target.convert
        _dictionary = target.convert
        _handleError = target.handleError
        parameters = target.parameters
    }

    func convert(data: Data) throws -> T {
        return try _map(data)
    }
    
    func convert(dictionary: Any) throws -> T {
        return try _dictionary(dictionary)
    }
    
    func handleError(error: Error) -> T {
        return _handleError(error)
    }
}

enum TargetParamNames: String {
    case httpMethod = "httpMethod"
    case path = "path"
    case body = "body"
    case retryCount = "retryCount"
    case timeout = "timeout"
}

protocol RequestRetrier {
    func isRetry(response: URLResponse?, error: Error?) -> Bool
}

class ApiRequestRetrier: RequestRetrier {
    var retries: Int = 0
    
    init(retries: Int) {
        self.retries = retries
    }
    
    func isRetry(response: URLResponse?, error: Error?) -> Bool {
        if retries < 1 {
            return false
        } else {
            retries -= 1
            if error != nil {
                return true
            } else {
                if let response = response as? HTTPURLResponse  {
                    let statusCode = response.statusCode
                    if (500...600).contains(statusCode) {
                        return true
                    } else {
                        return false
                    }
                } else {
                    return true
                }
            }
        }
    }
}

extension String: Error { }

func newJSONDecoder() -> JSONDecoder {
    let decoder = JSONDecoder()
    if #available(iOS 10.0, OSX 10.12, tvOS 10.0, watchOS 3.0, *) {
        decoder.dateDecodingStrategy = .iso8601
    }
    return decoder
}

func newJSONEncoder() -> JSONEncoder {
    let encoder = JSONEncoder()
    if #available(iOS 10.0, OSX 10.12, tvOS 10.0, watchOS 3.0, *) {
        encoder.dateEncodingStrategy = .iso8601
    }
    return encoder
}
