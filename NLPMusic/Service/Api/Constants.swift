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

public typealias UserAgent = String

public struct Constants {
    public static let appId: String = "6146827"
    public static let clientSecret: String = "qVxWRF1CwHERuIrKBnqe"
    public static let userFields: String = "image_status,emoji_status,first_name_nom,first_name_gen,first_name_dat,first_name_acc,first_name_ins, first_name_abl,last_name_nom,last_name_gen,last_name_dat,last_name_acc,last_name_ins,last_name_abl,counters,photo_id,verified,sex,bdate,city,country,home_town,has_photo,photo_50,photo_100,photo_200_orig,photo_200,photo_400_orig,photo_max,photo_max_orig,domain,has_mobile,contacts,site,education,universities,status,last_seen,followers_count,common_count,occupation,nickname,relatives,relation,personal,connections,exports,activities,interests,music,movies,tv,books,games,about,quotes,can_post,can_see_all_posts,can_see_audio,can_write_private_message,can_send_friend_request,is_favorite,is_hidden_from_feed,timezone,screen_name,maiden_name,crop_photo,is_friend,friend_status,career,military,blacklisted,blacklisted_by_me,can_be_invited_group,status_id,online_info"
    public static var userAgent: UserAgent {
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
