//
//  Audio.swift
//  VKM
//
//  Created by Ярослав Стрельников on 18.05.2021.
//

import Foundation
import ObjectMapper

open class Response<T: Mappable>: Mappable {
    public required init?(map: Map) {}
    
    open func mapping(map: Map) {
        response <- map["response"]
    }

    var response: T!
}

open class AudioResponse: Mappable {
    public required init?(map: Map) {}
    
    open func mapping(map: Map) {
        count <- map["count"]
        items <- map["items"]
    }
    
    var count: Int = 0
    var items: [AudioItem] = []
}

import CoreStore

final class AudioDataStackService: NSObject {
    static let audios: ListPublisher<AudioItem> = {
        let list = dataStack.publishList(
            From<AudioItem>(),
            OrderBy<AudioItem>(.descending("date"))
        )
        return list
    }()
    
    static let dataStack: DataStack = {
        let dataStack = DataStack(CoreStoreSchema(modelVersion: "V1", entities: [Entity<AudioItem>("AudioItem")]))
        try! dataStack.addStorageAndWait(SQLiteStore(fileName: "AudioItem.sqlite", localStorageOptions: .recreateStoreOnModelMismatch))
        return dataStack
    }()
    
    static func removeDataStack(success: @escaping(AudioItem.Type) -> (), failed: @escaping(CoreStoreError) -> ()) throws {
        dataStack.perform { transaction in
            try transaction.deleteAll(From<AudioItem>())
        } completion: { result in
            switch result {
            case .success:
                success(AudioItem.self)
            case .failure(let coreStoreError):
                failed(coreStoreError)
            }
        }
    }
}

extension Int {
    var duration: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .positional

        let formattedString = formatter.string(from: TimeInterval(self))!
        return formattedString
    }
}
