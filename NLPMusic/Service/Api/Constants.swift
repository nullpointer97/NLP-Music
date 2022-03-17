//
//  Constants.swift
//  Api
//
//  Created by Ярослав Стрельников on 19.10.2020.
//

import Foundation
import UIKit

var currentUserId: Int {
    get {
        UserDefaults.standard.integer(forKey: "userId")
    } set {
        UserDefaults.standard.set(newValue, forKey: "userId")
    }
}

typealias UserAgent = String

public struct Constants {
    public static let appId: String = "2274003"
    public static let clientSecret: String = "hHbZxrka2uZ6jB1inYsH"
    public static var userAgent: String {
        return configureUserAgent()
    }
    
    private static func configureUserAgent() -> UserAgent {
        let currentiOSVersion = UIDevice.current.systemVersion
        let currentDeviceName = UIDevice.current.modelName
        
        let ua = "VKAndroidApp/7.7.2 (iOS \(currentiOSVersion); SDK \(currentiOSVersion); x64; \(currentDeviceName); \(Locale.current.languageCode?.lowercased() ?? "ru"); \(UIScreen.main.bounds.height.intValue * UIScreen.main.scale.intValue)x\(UIScreen.main.bounds.width.intValue * UIScreen.main.scale.intValue))"
        print(ua)
        
        return ua
    }
}

func percent(with value: CGFloat, from percent: CGFloat) -> CGFloat {
    let val = value * percent
    return val / 100.0
}
