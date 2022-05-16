//
//  NLPCollectionHeaderCollectionReusableView.swift
//  NLPMusic
//
//  Created by Ярослав Стрельников on 15.05.2022.
//  Copyright © 2022 NP-Team. All rights reserved.
//

import UIKit

class NLPCollectionHeaderCollectionReusableView: UICollectionReusableView {
    private var separatorView = UIView()
    private var titleLabel = UILabel()
    private var showAllButton = UIButton()
    
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
    
    var isNeedShowAll: Bool = true {
        didSet {
            showAllButton.isHidden = !isNeedShowAll
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
    
    private func commonInit() {
        separatorView.add(to: self)
        showAllButton.add(to: self)
        titleLabel.add(to: self)
        
        separatorView.autoPinEdge(.top, to: .top, of: self)
        separatorView.autoPinEdge(.leading, to: .leading, of: self)
        separatorView.autoPinEdge(.trailing, to: .trailing, of: self)
        separatorView.autoSetDimension(.height, toSize: 0.5)
        separatorView.backgroundColor = .adaptableBorder
        
        showAllButton.autoPinEdge(.trailing, to: .trailing, of: self)
        showAllButton.autoAlignAxis(toSuperviewAxis: .horizontal)
        showAllButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .regular)
        showAllButton.setTitle("Показать все", for: .normal)
        showAllButton.setTitleColor(.getAccentColor(fromType: .common), for: .normal)
        showAllButton.autoSetDimensions(to: .custom(96, 44))
        
        titleLabel.autoPinEdge(.leading, to: .leading, of: self)
        titleLabel.autoPinEdge(.trailing, to: .leading, of: showAllButton, withOffset: -12)
        titleLabel.autoAlignAxis(toSuperviewAxis: .horizontal)
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = .label
    }
}
