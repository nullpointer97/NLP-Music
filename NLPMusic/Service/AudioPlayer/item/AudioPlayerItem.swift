//
//  AudioItem.swift
//  AudioPlayer
//
//  Created by Kevin DELANNOY on 12/03/16.
//  Copyright © 2016 Kevin Delannoy. All rights reserved.
//

import AVFoundation
import ObjectMapper
#if os(iOS) || os(tvOS)
import UIKit
import MediaPlayer

public typealias Image = UIImage
#else
import Cocoa

public typealias Image = NSImage
#endif

// MARK: - AudioQuality

/// `AudioQuality` differentiates qualities for audio.
///
/// - low: The lowest quality.
/// - medium: The quality between highest and lowest.
/// - high: The highest quality.
public enum AudioQuality: Int {
    case low = 0
    case medium = 1
    case high = 2
}

public protocol PlayableAudio: Equatable {
    var artist: String? { get set }
    var title: String? { get set }
    var albumName: String? { get set }
    var date: Int? { get set }
    var subtitle: String? { get set }
    var duration: Int? { get set }
    var id: Int { get set }
    var url: String? { get set }
    var isHQ: Bool? { get set }
    var isExplicit: Bool? { get set }
    var albumThumb135: String? { get set }
    var albumThumb300: String? { get set }
    var albumThumb600: String? { get set }
    var isPlaying: Bool? { get }
    var isPaused: Bool? { get }
    var isDownloaded: Bool { get }
}

// MARK: - AudioItemURL

/// `AudioItemURL` contains information about an Item URL such as its quality.
public struct AudioItemURL {
    /// The quality of the stream.
    public let quality: AudioQuality
    
    /// The url of the stream.
    public let url: URL
    
    /// Initializes an AudioItemURL.
    ///
    /// - Parameters:
    ///   - quality: The quality of the stream.
    ///   - url: The url of the stream.
    public init?(quality: AudioQuality, url: URL?) {
        guard let url = url else { return nil }
        
        self.quality = quality
        self.url = url
    }
}

// MARK: - AudioItem

/// An `AudioItem` instance contains every piece of information needed for an `AudioPlayer` to play.
///
/// URLs can be remote or local.
import CoreStore
import SwiftyJSON
import CoreData
import RNCryptor

open class AudioItem: CoreStoreObject, ImportableUniqueObject {
    public typealias UniqueIDType = Int
    
    public typealias ImportSource = AudioPlayerItem

    public static var uniqueIDKeyPath: String {
        return #keyPath(AudioItem.id)
    }
    
    public static func uniqueID(from source: AudioPlayerItem, in transaction: BaseDataTransaction) throws -> Int? {
        return source.id
    }
    
    public func update(from source: AudioPlayerItem, in transaction: BaseDataTransaction) throws {
        date = source.date
        subtitle = source.subtitle
        duration = source.duration
        id = source.id
        ownerId = source.ownerId
        url = source.url
        isHQ = source.isHQ
        isExplicit = source.isExplicit
        title = source.title
        artist = source.artist
        albumName = source.albumName
        albumThumb135 = source.albumThumb135
        albumThumb300 = source.albumThumb300
        albumThumb600 = source.albumThumb600
        isPaused = source.isPaused
        isPlaying = source.isPlaying
    }
    
    public var uniqueIDValue: Int {
        get { return id }
        set { id = newValue }
    }
    
    @Field.Stored("date")
    var date: Int?

    @Field.Stored("subtitle")
    var subtitle: String?
    
    @Field.Stored("duration")
    var duration: Int?
    
    @objc
    @Field.Stored("id")
    var id: Int = 0
    
    @Field.Stored("ownerId")
    var ownerId: Int = 0
    
    @Field.Stored("url")
    var url: String?
    
    @Field.Stored("isHQ")
    var isHQ: Bool?
    
    @Field.Stored("isExplicit")
    var isExplicit: Bool?
    
    @Field.Stored("albumThumb135")
    var albumThumb135: String?
    
    @Field.Stored("albumThumb300")
    var albumThumb300: String?
    
    @Field.Stored("albumThumb600")
    var albumThumb600: String?
    
    var songName: String? {
        get {
            return "\(artist ?? "unknown")__\(title ?? "unknown")".lowercased().replacingOccurrences(of: " ", with: "_")
        }
    }
    
    let documentsDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("music_cache")
    
    class MainArtists: Mappable {
        public required init?(map: Map) {}
        
        public func mapping(map: Map) {
            name <- map["name"]
            id <- map["id"]
        }
        
        var name: String = ""
        var id: String = ""
    }
    
    class Album: Mappable {
        public required init?(map: Map) {}
        
        public func mapping(map: Map) {
            thumb <- map["thumb"]
        }
        
        var thumb: Thumb?
        
        class Thumb: Mappable {
            public required init?(map: Map) {}
            
            public func mapping(map: Map) {
                photo135 <- map["photo_135"]
                photo34 <- map["photo_34"]
                photo300 <- map["photo_300"]
                photo600 <- map["photo_600"]
                photo270 <- map["photo_270"]
                width <- map["width"]
                height <- map["height"]
            }
            
            var photo135: String?
            var photo34: String?
            var photo300: String?
            var photo600: String?
            var photo270: String?
            var width: Int = 0
            var height: Int = 0
        }
    }
    
    @Field.Stored("isPlaying")
    public var isPlaying: Bool?
    
    @Field.Stored("isPaused")
    public var isPaused: Bool?
    
    @Field.Virtual("isDownloaded", customGetter: { (object, field) in
        guard let stringUrl = object.$url.value, let url = URL(string: stringUrl) else { return false }
        
        var songName = "\(object.$artist.value ?? "unknown")__\(object.$title.value ?? "unknown")".lowercased().replacingOccurrences(of: " ", with: "_")
        
        let destinationUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent("music_cache")
            .appendingPathComponent("\(songName).\(url.pathExtension)")
        
        if FileManager.default.fileExists(atPath: destinationUrl.path) {
            print("Item downloaded")
            return true
        } else {
            print("Item not downloaded")
            return false
        }
    })
    var isDownloaded: Bool
    
    var soundUrl: URL? {
        guard let stringUrl = url, let url = URL(string: stringUrl) else { return nil }
        let destinationUrl = documentsDirectoryURL.appendingPathComponent("\(songName ?? "unknown").\(url.pathExtension)")

        if FileManager.default.fileExists(atPath: destinationUrl.path) {
            return destinationUrl
        } else {
            return url
        }
    }
    
    var lyrics: String? {
        guard let stringUrl = url, let url = URL(string: stringUrl) else { return nil }
        let asset = AVAsset(url: url)
        return asset.lyrics
    }
    
    public func removeAudio() throws {
        if let stringUrl = url, let url = URL(string: stringUrl) {
            let destinationUrl = documentsDirectoryURL.appendingPathComponent("\(songName ?? "unknown").\(url.pathExtension)")
            
            if !FileManager.default.fileExists(atPath: destinationUrl.path) {
                print("404: File not found")
            } else {
                try FileManager.default.removeItem(at: destinationUrl)
                NotificationCenter.default.post(name: NSNotification.Name("didRemoveAudio"), object: nil, userInfo: ["item": self])
            }
        } else {
            throw "Audio not contain URL"
        }
    }
    
    // MARK: Additional properties
    
    /// The artist of the item.
    ///
    /// This can change over time which is why the property is dynamic. It enables KVO on the property.
    @Field.Stored("artist")
    public dynamic var artist: String?
    
    /// The title of the item.
    ///
    /// This can change over time which is why the property is dynamic. It enables KVO on the property.
    @Field.Stored("title")
    public dynamic var title: String?
    
    /// The album of the item.
    ///
    /// This can change over time which is why the property is dynamic. It enables KVO on the property.
    @Field.Stored("albumName")
    public dynamic var albumName: String?
    
    /// The artwork image of the item.
    ///
    /// This can change over time which is why the property is dynamic. It enables KVO on the property.
    public dynamic var artwork: MPMediaItemArtwork? {
        return MPMediaItemArtwork(boundsSize: .identity(512)) { _ in
            return UIImage()
        }
    }
    
    // MARK: Metadata
    
    /// Parses the metadata coming from the stream/file specified in the URL's. The default behavior is to set values
    /// for every property that is nil. Customization is available through subclassing.
    ///
    /// - Parameter items: The metadata items.
    public func parseMetadata(_ items: [AVMetadataItem]) {
        items.forEach {
            if let commonKey = $0.commonKey {
                switch commonKey {
                case .commonKeyTitle where title == nil:
                    title = $0.value as? String
                case .commonKeyArtist where artist == nil:
                    artist = $0.value as? String
                default:
                    break
                }
            }
        }
    }
    
    public static func == (lhs: AudioItem, rhs: AudioItem) -> Bool {
        return lhs.id == rhs.id
    }
}

public class AudioPlayerItem: NSObject {
    init(from source: AudioItem) {
        date = source.date
        subtitle = source.subtitle
        duration = source.duration
        id = source.id
        ownerId = source.ownerId
        url = source.url
        isHQ = source.isHQ
        isExplicit = source.isExplicit
        title = source.title
        artist = source.artist
        albumName = source.albumName
        albumThumb135 = source.albumThumb135
        albumThumb300 = source.albumThumb300
        albumThumb600 = source.albumThumb600
    }
    
    init(fromJSON json: JSON) {
        date = json["date"].int
        subtitle = json["subtitle"].string
        duration = json["duration"].int
        id = json["id"].intValue
        ownerId = json["owner_id"].intValue
        url = json["url"].string
        isHQ = json["is_hq"].bool
        isExplicit = json["is_explicit"].bool
        title = json["title"].string
        artist = json["artist"].string
        albumName = json["album"]["title"].string
        albumThumb135 = json["album"]["thumb"]["photo_135"].string
        albumThumb300 = json["album"]["thumb"]["photo_300"].string
        albumThumb600 = json["album"]["thumb"]["photo_600"].string
    }
    
    var date: Int?
    var subtitle: String?
    var duration: Int?
    var id: Int = 0
    var ownerId: Int = 0
    var url: String?
    var isHQ: Bool?
    var isExplicit: Bool?
    var albumThumb135: String?
    var albumThumb300: String?
    var albumThumb600: String?
    
    weak var delegate: DownloadItemProtocol?
    
    var downloadStatus: DownloadStatus = .none
    
    var downloadProgress: Double = 0 {
        didSet {
            delegate?.download(self, progress: downloadProgress)
        }
    }
    
    var songName: String? {
        get {
            return "\(artist ?? "unknown")__\(title ?? "unknown")__\(id)".lowercased().replacingOccurrences(of: " ", with: "_")
        }
    }

    var documentsDirectoryURL: URL { FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("music_cache") }
    
    public var isPlaying: Bool {
        let service = AudioService.instance
        return service.player?.currentItem?.id == id && service.player?.state == .playing
    }

    public var isPaused: Bool {
        let service = AudioService.instance
        return service.player?.currentItem?.id == id && service.player?.state == .paused
    }

    public var isDownloaded: Bool {
        guard let stringUrl = url, let url = URL(string: stringUrl) else { return false }

        let destinationUrl = documentsDirectoryURL.appendingPathComponent("\(songName ?? "").\(url.pathExtension)")
        
        return FileManager.default.fileExists(atPath: destinationUrl.path)
    }
    
    var soundUrl: URL? {
        guard let stringUrl = url, let url = URL(string: stringUrl) else { return nil }
        let destinationUrl = documentsDirectoryURL.appendingPathComponent("\(songName ?? "unknown").\(url.pathExtension)")
        
        if FileManager.default.fileExists(atPath: destinationUrl.path) {
            return destinationUrl
        } else {
            return url
        }
    }
    
    var lyrics: String? {
        guard let stringUrl = url, let url = URL(string: stringUrl) else { return nil }
        let asset = AVAsset(url: url)
        return asset.lyrics
    }
    
    public func downloadAudio() throws {
        if Settings.downloadOnlyWifi && connectionType == .wifi || !Settings.downloadOnlyWifi {
            try download()
        } else {
            throw "Загрузка только через Wi-Fi"
        }
        
        func download() throws {
            if let stringUrl = url, let url = URL(string: stringUrl) {
                let destinationUrl = documentsDirectoryURL.appendingPathComponent("\(songName ?? "unknown").\(url.pathExtension)")
                
                if FileManager.default.fileExists(atPath: destinationUrl.path) {
                    print("The file already exists at path")
                } else {
                    DispatchQueue.global(qos: .background).async {
                        URLSession.shared.downloadTask(with: url) { location, response, error in
                            guard let location = location, error == nil else { return }
                            do {
                                try FileManager.default.moveItem(at: location, to: destinationUrl)
                                try AudioDataStackService.dataStack.perform { transaction in
                                    do {
                                        _ = try transaction.importUniqueObject(Into<AudioItem>(),source: self)
                                        NotificationCenter.default.post(name: NSNotification.Name("didDownloadAudio"), object: nil, userInfo: ["item": self])
                                    } catch {
                                        print(error.localizedDescription)
                                    }
                                }
                            } catch {
                                print(error)
                            }
                        }.resume()
                    }
                }
            } else {
                throw "Audio not contain URL"
            }
        }
    }
    
    public func removeAudio() throws {
        if let stringUrl = url, let url = URL(string: stringUrl) {
            let destinationUrl = documentsDirectoryURL.appendingPathComponent("\(songName ?? "unknown").\(url.pathExtension)")
            
            if !FileManager.default.fileExists(atPath: destinationUrl.path) {
                print("404: File not found")
            } else {
                try FileManager.default.removeItem(at: destinationUrl)
                
                try AudioDataStackService.dataStack.perform { transaction in
                    do {
                        _ = try transaction.deleteAll(From<AudioItem>(), [Where<AudioItem>(\.$url == stringUrl)])
                    } catch {
                        print(error.localizedDescription)
                    }
                }
                
                NotificationCenter.default.post(name: NSNotification.Name("didRemoveAudio"), object: nil, userInfo: ["item": self])
            }
        } else {
            throw "Audio not contain URL"
        }
    }
    
    // MARK: Additional properties
    
    /// The artist of the item.
    ///
    /// This can change over time which is why the property is dynamic. It enables KVO on the property.
    
    public dynamic var artist: String?
    
    /// The title of the item.
    ///
    /// This can change over time which is why the property is dynamic. It enables KVO on the property.
    
    public dynamic var title: String?
    
    /// The album of the item.
    ///
    /// This can change over time which is why the property is dynamic. It enables KVO on the property.
    
    public dynamic var albumName: String?
    
    /// The artwork image of the item.
    ///
    /// This can change over time which is why the property is dynamic. It enables KVO on the property.
    public dynamic var artwork: MPMediaItemArtwork? {
        return MPMediaItemArtwork(boundsSize: .identity(512)) { _ in
            return UIImage()
        }
    }
    
    // MARK: Metadata
    
    /// Parses the metadata coming from the stream/file specified in the URL's. The default behavior is to set values
    /// for every property that is nil. Customization is available through subclassing.
    ///
    /// - Parameter items: The metadata items.
    public func parseMetadata(_ items: [AVMetadataItem]) {
        items.forEach {
            if let commonKey = $0.commonKey {
                switch commonKey {
                case .commonKeyTitle where title == nil:
                    title = $0.value as? String
                case .commonKeyArtist where artist == nil:
                    artist = $0.value as? String
                default:
                    break
                }
            }
        }
    }
    
    func didStartDownload() {
        delegate?.didStarDownload(self)
    }
    
    func didFinishDownload() {
        delegate?.didFinishDownload(self)
    }
}

fileprivate extension URL {
    
    func withScheme(_ scheme: String) -> URL? {
        var components = URLComponents(url: self, resolvingAgainstBaseURL: false)
        components?.scheme = scheme
        return components?.url
    }
    
}

public extension URL {

    /// SwifterSwift: Initializes an `URL` object with a base URL and a relative string. If `string` was malformed, returns `nil`.
    /// - Parameters:
    ///   - string: The URL string with which to initialize the `URL` object. Must conform to RFC 2396. `string` is interpreted relative to `url`.
    ///   - url: The base URL for the `URL` object.
    init?(string: String?, relativeTo url: URL? = nil) {
        guard let string = string else { return nil }
        self.init(string: string, relativeTo: url)
    }

}

func sizeOfFolder(_ folderPath: String) -> String? {
    do {
        let contents = try FileManager.default.contentsOfDirectory(atPath: folderPath)
        var folderSize: Int64 = 0
        for content in contents {
            do {
                let fullContentPath = folderPath + "/" + content
                let fileAttributes = try FileManager.default.attributesOfItem(atPath: fullContentPath)
                folderSize += fileAttributes[FileAttributeKey.size] as? Int64 ?? 0
            } catch _ {
                continue
            }
        }

        /// This line will give you formatted size from bytes ....
        let fileSizeStr = ByteCountFormatter.string(fromByteCount: folderSize, countStyle: ByteCountFormatter.CountStyle.binary)
        return fileSizeStr

    } catch let error {
        print(error.localizedDescription)
        return nil
    }
}

func sizeOfFolder(_ folderPath: String) -> Int64 {
    do {
        let contents = try FileManager.default.contentsOfDirectory(atPath: folderPath)
        var folderSize: Int64 = 0
        for content in contents {
            do {
                let fullContentPath = folderPath + "/" + content
                let fileAttributes = try FileManager.default.attributesOfItem(atPath: fullContentPath)
                folderSize += fileAttributes[FileAttributeKey.size] as? Int64 ?? 0
            } catch _ {
                continue
            }
        }

        return folderSize
    } catch let error {
        print(error.localizedDescription)
        return 0
    }
}

protocol DownloadItemProtocol: AnyObject {
    func download(_ item: AudioPlayerItem, progress: Double)
    func didStarDownload(_ item: AudioPlayerItem)
    func didFinishDownload(_ item: AudioPlayerItem)
}

class AudioDownloadManager: NSObject {
    var activeDownloads: [URL: Download] = [ : ]
    private var documentsDirectoryURL: URL { FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("music_cache") }
    
    var session: URLSession!
    
    func download(item: AudioPlayerItem) throws {
        guard let url = URL(string: item.url) else { return }

        let download = Download(track: item)
        
        download.task = session.downloadTask(with: url)
        download.task?.resume()
        download.isDownloading = true

        activeDownloads[url] = download
    }
}

class Download {
    var isDownloading = false
    var progress: Float = 0
    var resumeData: Data?
    var task: URLSessionDownloadTask?
    var track: AudioPlayerItem

    init(track: AudioPlayerItem) {
        self.track = track
    }
}


/*
 
 Int -> 1561
 Float -> 1465123.123456
 Double -> 786445.123456789876543
 Stirng -> "XUI"
 Charachter -> "X"
 Bool -> true
 
 */
