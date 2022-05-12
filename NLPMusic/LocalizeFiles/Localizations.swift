//
//  Localizations.swift
//  NLPMusic
//
//  Created by Ярослав Стрельников on 12.05.2022.
//  Copyright © 2022 NP-Team. All rights reserved.
//

import Foundation

enum Localizations: String {
    case searchPlaceholder = "NLPSearchAudioViewController.Search.SearchPlaceholder"
}

extension String {
    static func localized(_ localizedString: Localizations, comment: String = "no comment") -> String {
        return NSLocalizedString(localizedString.rawValue, comment: comment)
    }
}
