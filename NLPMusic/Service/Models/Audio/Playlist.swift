//
//  Playlist.swift
//  VKM
//
//  Created by Ярослав Стрельников on 26.05.2021.
//

import Foundation
import ObjectMapper

// MARK: - Response
class PlaylistResponse: Mappable {
    required init?(map: Map) { }
    
    func mapping(map: Map) {
        count <- map["count"]
        items <- map["items"]
    }
    
    var count: Int = 0
    var items: [Playlist] = []
}

// MARK: - Item
class Playlist: NSObject, Mappable {
    required init?(map: Map) { }
    
    func mapping(map: Map) {
        id <- map["id"]
        ownerId <- map["owner_id"]
        type <- map["type"]
        title <- map["title"]
        itemDescription <- map["description"]
        count <- map["count"]
        genres <- map["genres"]
        followers <- map["followers"]
        plays <- map["plays"]
        createTime <- map["create_time"]
        updateTime <- map["update_time"]
        isFollowing <- map["is_following"]
        year <- map["year"]
        original <- map["original"]
        photo <- map["photo"]
        permissions <- map["permissions"]
        subtitleBadge <- map["subtitle_badge"]
        playButton <- map["play_button"]
        accessKey <- map["access_key"]
        isExplicit <- map["is_explicit"]
        mainArtists <- map["main_artists"]
        albumType <- map["album_type"]
    }
    
    var id, ownerId, type: Int!
    var title: String!
    var itemDescription: String?
    var count, followers, plays, createTime: Int!
    var updateTime: Int!
    var genres: [Genre] = []
    var isFollowing: Bool!
    var year: Int?
    var original: Original?
    var photo: Photo?
    var permissions: Permissions?
    var subtitleBadge, playButton: Bool?
    var accessKey: String!
    var isExplicit: Bool?
    var mainArtists: [MainArtist]? = []
    var albumType: String?
}

class MainArtist: Mappable {
    var name, domain, id: String?
    
    required init?(map: Map) { }
    
    func mapping(map: Map) {
        id <- map["id"]
        name <- map["name"]
        domain <- map["domain"]
    }
}

// MARK: - Genre
class Genre: Mappable {
    required init?(map: Map) { }
    
    func mapping(map: Map) {
        id <- map["id"]
        name <- map["name"]
    }

    var id: Int?
    var name: String?
}

// MARK: - Original
class Original: Mappable {
    required init?(map: Map) { }
    
    func mapping(map: Map) {
        playlistId <- map["playlist_id"]
        ownerId <- map["owner_id"]
        accessKey <- map["access_key"]
    }

    var playlistId, ownerId: Int?
    var accessKey: String?
}

// MARK: - Permissions
class Permissions: Mappable {
    required init?(map: Map) { }
    
    func mapping(map: Map) {
        play <- map["play"]
        share <- map["share"]
        edit <- map["edit"]
        follow <- map["follow"]
    }

    var play, share, edit, follow: Bool?
}

// MARK: - Photo
class Photo: Mappable {
    required init?(map: Map) { }
    
    func mapping(map: Map) {
        width <- map["width"]
        height <- map["height"]
        photo34 <- map["photo_34"]
        photo68 <- map["photo_68"]
        photo135 <- map["photo_135"]
        photo270 <- map["photo_270"]
        photo300 <- map["photo_300"]
        photo600 <- map["photo_600"]
        photo1200 <- map["photo_1200"]
    }

    var width, height: Int!
    var photo34, photo68, photo135, photo270: String?
    var photo300, photo600, photo1200: String?
}
