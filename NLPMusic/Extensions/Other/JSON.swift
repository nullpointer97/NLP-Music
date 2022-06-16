//
//  JSON.swift
//  vkExtended
//
//  Created by Ярослав Стрельников on 26.10.2020.
//

import Foundation

func decodeJSON<T: Decodable>(type: T.Type, from: Data?) -> T? {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    guard let data = from, let response = try? decoder.decode(type.self, from: data) else { return nil }
    return response
}
