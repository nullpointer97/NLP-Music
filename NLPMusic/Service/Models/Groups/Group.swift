//
//  Group.swift
//  NLPMusic
//
//  Created by Ярослав Стрельников on 16.05.2022.
//  Copyright © 2022 NP-Team. All rights reserved.
//

import Foundation
import SwiftyJSON

public class Group: NSObject {
    var id: String = ""
    var image: [ItemImage] = []
    var title: String = ""
    var subtitle: String? = nil
    var url: String = ""
    var isVerified: Bool = false
    
    func parse(from json: JSON) -> Group {
        id = json["id"].stringValue
        image = json["image"].arrayValue.compactMap { ItemImage().parse(from: $0) }
        title = json["title"].stringValue
        subtitle = json["subtitle"].string
        url = json["url"].stringValue
        
        isVerified = json["meta"]["icon"].stringValue == "verified"
        
        return self
    }
}

public class ItemImage: NSObject {
    var url: String = ""
    var width: CGFloat = 0
    var height: CGFloat = 0
    
    func parse(from json: JSON) -> ItemImage {
        url = json["url"].stringValue
        width = CGFloat(json["width"].floatValue)
        height = CGFloat(json["height"].floatValue)
        
        return self
    }
}
