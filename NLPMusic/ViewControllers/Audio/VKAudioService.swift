//
//  VKAudioService.swift
//  vkmusic
//
//  Created by Ярослав Стрельников on 03.02.2022.
//  Copyright © 2022 NP-Team. All rights reserved.
//

import Foundation
import CoreStore

final class VKAudioDataStackService: NSObject {
    static let conversationsCount = UserDefaults.standard.integer(forKey: "conversationsCount")
    
    static func getAudios(where: Where<AudioItem> = Where<AudioItem>()) -> ListPublisher<AudioItem> {
        let list = dataStack.publishList(
            From<AudioItem>(),
            `where`,
            OrderBy<AudioItem>(.descending("date"))
        )
        return list
    }
    
    static let dataStack: DataStack = {
        let dataStack = DataStack(CoreStoreSchema(modelVersion: "V1", entities: [Entity<AudioItem>("AudioItem")]))
        try! dataStack.addStorageAndWait(SQLiteStore(fileName: "AudioItem.sqlite", localStorageOptions: .recreateStoreOnModelMismatch))
        return dataStack
    }()
    
    static func removeDataStack(success: @escaping ((AudioItem.Type) -> Void), failed: @escaping ((CoreStoreError) -> Void)) throws {
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

final class DataStackService<T: CoreStoreObject>: NSObject {
    let objectsCount = UserDefaults.standard.integer(forKey: "\(T.self)Count")
    
    func getObjects(with predicate: NSPredicate? = nil) -> ListPublisher<T> {
        let list: ListPublisher<T>
        list = dataStack.publishList(
            From<T>(),
            OrderBy<T>(
                .descending("date")
            ),
            Tweak { request in
                request.predicate = predicate
            }
        )
        return list
    }
    
    let dataStack: DataStack = {
        let dataStack = DataStack(CoreStoreSchema(modelVersion: "V1", entities: [Entity<T>("\(T.self)")]))
        try! dataStack.addStorageAndWait(SQLiteStore(fileName: "\(T.self).sqlite", localStorageOptions: .recreateStoreOnModelMismatch))
        return dataStack
    }()
    
    func removeDataStack(success: @escaping ((T.Type) -> Void), failed: @escaping ((CoreStoreError) -> Void)) throws {
        dataStack.perform { transaction in
            try transaction.deleteAll(From<T>())
        } completion: { result in
            switch result {
            case .success:
                success(T.self)
            case .failure(let coreStoreError):
                failed(coreStoreError)
            }
        }
    }
}
