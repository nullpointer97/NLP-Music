//
//  NLPModalViewController.swift
//  NLPMusic
//
//  Created by Ярослав Стрельников on 02.04.2022.
//  Copyright © 2022 NP-Team. All rights reserved.
//

import Foundation
import UIKit

open class NLPModalViewController: NLPBaseViewController, PanModalPresentable {
    public var panScrollable: UIScrollView? {
        return nil
    }
    
    public var longFormHeight: PanModalHeight {
        return .intrinsicHeight
    }
    
    public var shortFormHeight: PanModalHeight {
        return .intrinsicHeight
    }
    
    public var cornerRadius: CGFloat {
        return 16
    }
    
    public var springDamping: CGFloat {
        return 1
    }
    
    public var dragIndicatorBackgroundColor: UIColor {
        return .white
    }
    
    public var dragIndicatorOffset: CGFloat {
        return -12
    }
    
    public var transitionDuration: Double {
        return 0.3
    }
}
