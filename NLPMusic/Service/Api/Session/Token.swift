//
//  Token.swift
//  vkExtended
//
//  Created by Ярослав Стрельников on 09.11.2020.
//

import Foundation

protocol TokenMaker: AnyObject {
    func token(token: String) -> InvalidatableToken
}

public protocol Token: AnyObject {
    var token: String { get }
    
    func get() -> String
}

public protocol InvalidatableToken: NSCoding, Token {
    func invalidate()
    func deactivate()
    func activate()
}

final class TokenImpl: NSObject, InvalidatableToken {
    public internal(set) var token: String
    
    init(token: String) {
        self.token = token
    }
    
    func get() -> String {
        return token
    }
    
    func invalidate() {
        token = "invalidate"
    }
    
    func deactivate() {
        token.append("_deactivated")
    }
    
    func activate() {
        token = token.replacingOccurrences(of: "_deactivated", with: "")
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(token, forKey: "token")
    }
    
    required init?(coder aDecoder: NSCoder) {
        guard let token = aDecoder.decodeObject(forKey: "token") as? String else { return nil }
        
        self.token = token
    }
}
