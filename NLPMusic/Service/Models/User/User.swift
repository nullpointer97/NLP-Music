//
//  User.swift
//  VKM
//
//  Created by Ярослав Стрельников on 15.03.2021.
//

import Foundation
import CoreStore
import SwiftyJSON

final class User: CoreStoreObject, ImportableUniqueObject {
    typealias UniqueIDType = Int
    typealias ImportSource = (JSON, Int)
    
    var uniqueIDValue: Int {
        get { return id }
        set { id = newValue }
    }

    static var uniqueIDKeyPath: String { return #keyPath(User.id) }
    
    static func uniqueID(from source: (JSON, Int), in transaction: BaseDataTransaction) throws -> Int? {
        return source.0["id"].int
    }

    func update(from source: (JSON, Int), in transaction: BaseDataTransaction) throws {
        let index = source.1
        let source = source.0
        
        id = source["id"].intValue
        self.index = index
        isImportant = index < 5
        
        firstNameNom = source["first_name_nom"].stringValue
        firstNameGen = source["first_name_gen"].stringValue
        firstNameDat = source["first_name_dat"].stringValue
        firstNameAcc = source["first_name_acc"].stringValue
        firstNameIns = source["first_name_ins"].stringValue
        firstNameAbl = source["first_name_abl"].stringValue

        lastNameNom = source["last_name_nom"].stringValue
        lastNameGen = source["last_name_gen"].stringValue
        lastNameDat = source["last_name_dat"].stringValue
        lastNameAcc = source["last_name_acc"].stringValue
        lastNameIns = source["last_name_ins"].stringValue
        lastNameAbl = source["last_name_abl"].stringValue
        
        canAccessClosed = source["can_access_closed"].boolValue
        isClosed = source["is_closed"].boolValue
        canWritePrivateMessage = source["can_write_private_message"].intValue.boolValue
        screenName = source["screen_name"].stringValue
        lastSeen = source["online_info"]["last_seen"].intValue
        isOnline = source["online_info"]["is_online"].boolValue
        appId = source["online_info"]["app_id"].intValue
        isMobile = source["online_info"]["is_mobile"].boolValue
        sex = source["sex"].intValue
        verified = source["verified"].intValue
        photo100 = source["photo_100"].stringValue
        imageStatusUrl = source["image_status"]["images"].arrayValue.first?["url"].string
    }
    
    func didInsert(from source: (JSON, Int), in transaction: BaseDataTransaction) throws {
        let index = source.1
        let source = source.0
        
        id = source["id"].intValue
        self.index = index
        isImportant = index < 5

        firstNameNom = source["first_name_nom"].stringValue
        firstNameGen = source["first_name_gen"].stringValue
        firstNameDat = source["first_name_dat"].stringValue
        firstNameAcc = source["first_name_acc"].stringValue
        firstNameIns = source["first_name_ins"].stringValue
        firstNameAbl = source["first_name_abl"].stringValue

        lastNameNom = source["last_name_nom"].stringValue
        lastNameGen = source["last_name_gen"].stringValue
        lastNameDat = source["last_name_dat"].stringValue
        lastNameAcc = source["last_name_acc"].stringValue
        lastNameIns = source["last_name_ins"].stringValue
        lastNameAbl = source["last_name_abl"].stringValue
        
        canAccessClosed = source["can_access_closed"].boolValue
        isClosed = source["is_closed"].boolValue
        canWritePrivateMessage = source["can_write_private_message"].intValue.boolValue
        screenName = source["screen_name"].stringValue
        lastSeen = source["online_info"]["last_seen"].intValue
        isOnline = source["online_info"]["is_online"].boolValue
        appId = source["online_info"]["app_id"].intValue
        isMobile = source["online_info"]["is_mobile"].boolValue
        sex = source["sex"].intValue
        verified = source["verified"].intValue
        photo100 = source["photo_100"].stringValue
        imageStatusUrl = source["image_status"]["images"].arrayValue.first?["url"].string
    }
    
    @objc
    @Field.Stored("id")
    var id: Int = 0
    
    @Field.Stored("firstNameNom")
    var firstNameNom: String = ""
    
    @Field.Stored("firstNameGen")
    var firstNameGen: String = ""
    
    @Field.Stored("firstNameDat")
    var firstNameDat: String = ""
    
    @Field.Stored("firstNameAcc")
    var firstNameAcc: String = ""
    
    @Field.Stored("firstNameIns")
    var firstNameIns: String = ""
    
    @Field.Stored("firstNameAbl")
    var firstNameAbl: String = ""
    
    @Field.Stored("lastNameNom")
    var lastNameNom: String = ""
    
    @Field.Stored("lastNameGen")
    var lastNameGen: String = ""
    
    @Field.Stored("lastNameDat")
    var lastNameDat: String = ""
    
    @Field.Stored("lastNameAcc")
    var lastNameAcc: String = ""
    
    @Field.Stored("lastNameIns")
    var lastNameIns: String = ""
    
    @Field.Stored("lastNameAbl")
    var lastNameAbl: String = ""

    @Field.Stored("canAccessClosed")
    var canAccessClosed: Bool = false
    
    @Field.Stored("isClosed")
    var isClosed: Bool = false
    
    @Field.Stored("canWritePrivateMessage")
    var canWritePrivateMessage: Bool = true
    
    @Field.Stored("screenName")
    var screenName: String?
    
    @Field.Stored("lastSeen")
    var lastSeen: Int = 0
    
    @Field.Stored("isOnline")
    var isOnline: Bool = false
    
    @Field.Stored("appId")
    var appId: Int = 0
    
    @Field.Stored("isMobile")
    var isMobile: Bool = false
    
    @Field.Stored("sex")
    var sex: Int = 0
    
    @Field.Stored("verified")
    var verified: Int = 0
    
    @Field.Stored("photo100")
    var photo100: String = ""
    
    @Field.Stored("imageStatusUrl")
    var imageStatusUrl: String?
    
    @Field.Stored("index")
    var index: Int = 0
    
    @Field.Stored("isImportant")
    var isImportant: Bool = false
}

final class UserNames: CoreStoreObject {
    
    
    @Field.Relationship("user")
    var user: User?
}

final class NLPUser: NSObject {
    init(_ source: JSON) {
        id = source["id"].intValue
        isImportant = index < 5
        
        firstNameNom = source["first_name_nom"].stringValue
        firstNameGen = source["first_name_gen"].stringValue
        firstNameDat = source["first_name_dat"].stringValue
        firstNameAcc = source["first_name_acc"].stringValue
        firstNameIns = source["first_name_ins"].stringValue
        firstNameAbl = source["first_name_abl"].stringValue

        lastNameNom = source["last_name_nom"].stringValue
        lastNameGen = source["last_name_gen"].stringValue
        lastNameDat = source["last_name_dat"].stringValue
        lastNameAcc = source["last_name_acc"].stringValue
        lastNameIns = source["last_name_ins"].stringValue
        lastNameAbl = source["last_name_abl"].stringValue
        
        canAccessClosed = source["can_access_closed"].boolValue
        isClosed = source["is_closed"].boolValue
        canWritePrivateMessage = source["can_write_private_message"].intValue.boolValue
        screenName = source["screen_name"].stringValue
        lastSeen = source["online_info"]["last_seen"].intValue
        isOnline = source["online_info"]["is_online"].boolValue
        appId = source["online_info"]["app_id"].intValue
        isMobile = source["online_info"]["is_mobile"].boolValue
        sex = source["sex"].intValue
        verified = source["verified"].intValue
        photo100 = source["photo_100"].stringValue
        photo200 = source["photo_200"].stringValue
        imageStatusUrl = source["image_status"]["images"].arrayValue.first?["url"].string
    }

    var id: Int = 0
    var firstNameNom: String = ""
    var firstNameGen: String = ""
    var firstNameDat: String = ""
    var firstNameAcc: String = ""
    var firstNameIns: String = ""
    var firstNameAbl: String = ""
    var lastNameNom: String = ""
    var lastNameGen: String = ""
    var lastNameDat: String = ""
    var lastNameAcc: String = ""
    var lastNameIns: String = ""
    var lastNameAbl: String = ""
    var canAccessClosed: Bool = false
    var isClosed: Bool = false
    var canWritePrivateMessage: Bool = true
    var screenName: String?
    var lastSeen: Int = 0
    var isOnline: Bool = false
    var appId: Int = 0
    var isMobile: Bool = false
    var sex: Int = 0
    var verified: Int = 0
    var photo100: String = ""
    var photo200: String = ""
    var imageStatusUrl: String?
    var index: Int = 0
    var isImportant: Bool = false
}
