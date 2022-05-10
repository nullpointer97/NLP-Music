//
//  Optional.swift
//  NLPMusic
//
//  Created by Ярослав Стрельников on 02.04.2022.
//  Copyright © 2022 NP-Team. All rights reserved.
//

import Foundation
import UIKit
import CoreMedia

extension Optional where Wrapped == String {
    func safeUnwrap() -> String {
        return self ?? ""
    }
}
