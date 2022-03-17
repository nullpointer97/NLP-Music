//
//  ExtendedDelegate.swift
//  vkExtended
//
//  Created by Ярослав Стрельников on 09.11.2020.
//

import Foundation
public typealias ExtendedVKDelegate = ExtendedVKSessionDelegate & ExtendedVKAuthorizatorDelegate

public protocol ExtendedVKAuthorizatorDelegate: AnyObject {
    /// Called when VKExtended attempts get access to user account
    /// Should return set of permission scopes
    /// parameter sessionId: VKExtended session identifier
    func vkNeedsScopes(for sessionId: String) -> String
}

public protocol ExtendedVKSessionDelegate: AnyObject {
    /// Called when user grant access and VKExtended gets new session token
    /// Can be used for run VKExtended requests and save session data
    /// parameter sessionId: VKExtended session identifier
    func vkTokenCreated(for sessionId: String, info: [String: String])
    
    /// Called when existing session token was expired and successfully refreshed
    /// Most likely here you do not do anything
    /// parameter sessionId: VKExtended session identifier
    /// parameter info: Authorized user info
    func vkTokenUpdated(for sessionId: String, info: [String: String])
    
    /// Called when user was logged out
    /// Use this point to cancel all VKExtended requests and remove session data
    /// parameter sessionId: VKExtended session identifier
    func vkTokenRemoved(for sessionId: String)
}

extension ExtendedVKSessionDelegate {
    
    // Default dummy methods implementations
    // Allows using its optionally
    
    public func vkTokenCreated(for sessionId: String, info: [String: String]) {}
    public func vkTokenUpdated(for sessionId: String, info: [String: String]) {}
    public func vkTokenRemoved(for sessionId: String) {}
}
