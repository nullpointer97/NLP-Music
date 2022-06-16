//
//  NLPHeaderView.swift
//  NLPMusic
//
//  Created by Ярослав Стрельников on 12.05.2022.
//  Copyright © 2022 NP-Team. All rights reserved.
//

import Foundation
import UIKit

class NLPHeaderView: UIView {
    private var separatorView = UIView()
    private var titleLabel = UILabel()
    
    var title: String? {
        get { return titleLabel.text }
        set {
            titleLabel.text = newValue
            titleLabel.hideSkeleton()
        }
    }
    
    var attributedTitle: NSAttributedString? {
        get { return NSAttributedString(string: titleLabel.text ?? "") }
        set {
            titleLabel.attributedText = newValue
            titleLabel.hideSkeleton()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    func commonInit() {
        separatorView.add(to: self)
        titleLabel.add(to: self)
        
        separatorView.autoPinEdge(.top, to: .top, of: self)
        separatorView.autoPinEdge(.leading, to: .leading, of: self, withOffset: 16)
        separatorView.autoPinEdge(.trailing, to: .trailing, of: self, withOffset: -16)
        separatorView.autoSetDimension(.height, toSize: 0.5)
        separatorView.backgroundColor = .adaptableBorder
        
        titleLabel.autoPinEdge(.leading, to: .leading, of: self, withOffset: 16)
        titleLabel.autoPinEdge(.trailing, to: .trailing, of: self, withOffset: -16)
        titleLabel.autoAlignAxis(toSuperviewAxis: .horizontal)
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.isSkeletonable = true
    }
    
    func skeletone() {
        titleLabel.showAnimatedGradientSkeleton()
    }
}
