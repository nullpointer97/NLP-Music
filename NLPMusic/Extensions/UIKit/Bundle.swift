//
//  Bundle.swift
//  NLPMusic
//
//  Created by Ярослав Стрельников on 12.05.2022.
//  Copyright © 2022 NP-Team. All rights reserved.
//

import Foundation
import UIKit

private var bundleKey: UInt8 = 0

final class BundleExtension: Bundle {
    
    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        return (objc_getAssociatedObject(self, &bundleKey) as? Bundle)?.localizedString(forKey: key, value: value, table: tableName) ?? super.localizedString(forKey: key, value: value, table: tableName)
    }
}

extension Bundle {
    
    static let once: Void = { object_setClass(Bundle.main, type(of: BundleExtension())) }()
    
    static func set(language: Language) {
        Bundle.once
        
        let isLanguageRTL = Locale.characterDirection(forLanguage: language.code) == .rightToLeft
        UIView.appearance().semanticContentAttribute = isLanguageRTL == true ? .forceRightToLeft : .forceLeftToRight
        
        UserDefaults.standard.set(isLanguageRTL, forKey: "AppleTextDirection")
        UserDefaults.standard.set(isLanguageRTL, forKey: "NSForceRightToLeftWritingDirection")
        UserDefaults.standard.set([language.code], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
        
        guard let path = Bundle.main.path(forResource: language.code, ofType: "lproj") else {
            print("Failed to get a bundle path.")
            return
        }
        
        objc_setAssociatedObject(Bundle.main, &bundleKey, Bundle(path: path), objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

enum Language: Equatable {
    case english(English)
    case chinese(Chinese)
    case russian
    
    enum English {
        case us
        case uk
        case australian
        case canadian
        case indian
    }
    
    enum Chinese {
        case simplified
        case traditional
        case hongKong
    }
}

extension Language {
    
    var code: String {
        switch self {
        case .english(let english):
            switch english {
            case .us: return "en"
            case .uk: return "en-GB"
            case .australian: return "en-AU"
            case .canadian: return "en-CA"
            case .indian: return "en-IN"
            }
            
        case .chinese(let chinese):
            switch chinese {
            case .simplified: return "zh-Hans"
            case .traditional: return "zh-Hant"
            case .hongKong: return "zh-HK"
            }
            
        case .russian: return "ru-RU"
        }
    }
    
    var name: String {
        switch self {
        case .english(let english):
            switch english {
            case .us: return "English"
            case .uk: return "English (UK)"
            case .australian: return "English (Australia)"
            case .canadian: return "English (Canada)"
            case .indian: return "English (India)"
            }
            
        case .chinese(let chinese):
            switch chinese {
            case .simplified: return "简体中文"
            case .traditional: return "繁體中文"
            case .hongKong: return "繁體中文 (香港)"
            }
            
        case .russian: return "Русский"
        }
    }
}

extension Language {
    
    init?(languageCode: String?) {
        guard let languageCode = languageCode else { return nil }
        switch languageCode {
        case "en", "en-US": self = .english(.us)
        case "en-GB": self = .english(.uk)
        case "en-AU": self = .english(.australian)
        case "en-CA": self = .english(.canadian)
        case "en-IN": self = .english(.indian)
            
        case "zh-Hans": self = .chinese(.simplified)
        case "zh-Hant": self = .chinese(.traditional)
        case "zh-HK": self = .chinese(.hongKong)
            
        case "ru-RU": self = .russian
        default: return nil
        }
    }
}

struct LocaleManager {
    
    /// "ko-US" → "ko"
    static var languageCode: String? {
        guard var splits = Locale.preferredLanguages.first?.split(separator: "-"), let first = splits.first else { return nil }
        guard 1 < splits.count else { return String(first) }
        splits.removeLast()
        return String(splits.joined(separator: "-"))
    }
    
    static var language: Language? {
        return Language(languageCode: languageCode)
    }
}
