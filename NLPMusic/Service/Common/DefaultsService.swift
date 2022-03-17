//
//  DefaultsService.swift
//  VKM
//
//  Created by Ярослав Стрельников on 13.04.2021.
//

import Foundation
import UIKit
import CoreStore

open class DefaultsService<T>: NSObject {
    private var storage: UserDefaults {
        return UserDefaults.standard
    }
    
    open func set(value: T?, for key: String) {
        storage.set(value, forKey: key)
    }
    
    open func set(values: [T?], for keys: [String]) {
        values.enumerated().forEach { (index, value) in
            storage.set(value, forKey: keys[index])
        }
    }
    
    open func get(for key: String) -> T? {
        storage.value(forKey: key) as? T
    }
    
    open func remove(for key: String) {
        storage.removeObject(forKey: key)
    }
}

public enum VKMSettings<T> {
    
    public static subscript(_ key: String) -> T? { // the parameter key have a enum type `key`
        get { // need use `rawValue` to acess the string
            return DefaultsService<T>().get(for: key)
        }
        set { // need use `rawValue` to acess the string
            DefaultsService<T>().set(value: newValue, for: key)
        }
    }
}

func clearCache() {
    let fileManager = FileManager.default
    
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("music_cache").path

    do {
        let fileName = try fileManager.contentsOfDirectory(atPath: paths)
        
        for file in fileName {
            let filePath = URL(fileURLWithPath: paths).appendingPathComponent(file).absoluteURL
            try fileManager.removeItem(at: filePath)
        }
        
        try AudioDataStackService.dataStack.perform { transaction in
            do {
                _ = try transaction.deleteAll(From<AudioItem>())
            } catch {
                print(error.localizedDescription)
            }
        }
    } catch let error {
        print(error.localizedDescription)
    }
    
    NotificationCenter.default.post(name: NSNotification.Name("didCleanCache"), object: nil)
}
