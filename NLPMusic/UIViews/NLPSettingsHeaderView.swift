//
//  NLPSettingsHeaderView.swift
//  NLPMusic
//
//  Created by Ярослав Стрельников on 25.04.2022.
//  Copyright © 2022 NP-Team. All rights reserved.
//

import Foundation
import UIKit

class NLPSettingsHeaderView: UIView {
    public let imageView: ShadowImageView = {
        let imageView = ShadowImageView()
        imageView.imageView.contentMode = .scaleAspectFill
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    public let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textAlignment = .center
        label.textColor = .label
        return label
    }()
    
    public let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textAlignment = .center
        label.textColor = .getAccentColor(fromType: .common)
        return label
    }()
    
    var imageSizeConstraints: [NSLayoutConstraint] = []
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        createViews()
        setViewConstraints()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func createViews() {
        imageView.add(to: self)
        titleLabel.add(to: self)
        subtitleLabel.add(to: self)
    }
    
    private func setViewConstraints() {
        imageView.autoAlignAxis(toSuperviewAxis: .vertical)
        imageSizeConstraints = imageView.autoSetDimensions(to: .identity(100))
        imageView.imageView.drawBorder(50, width: 0.5, color: .adaptableBorder)
        
        titleLabel.autoPinEdge(.top, to: .bottom, of: imageView, withOffset: 16)
        titleLabel.autoPinEdge(.leading, to: .leading, of: self, withOffset: 16)
        titleLabel.autoPinEdge(.trailing, to: .trailing, of: self, withOffset: -16)
        titleLabel.autoSetDimension(.height, toSize: 24)
        
        subtitleLabel.autoPinEdge(.top, to: .bottom, of: titleLabel, withOffset: 4)
        subtitleLabel.autoPinEdge(.leading, to: .leading, of: self, withOffset: 16)
        subtitleLabel.autoPinEdge(.trailing, to: .trailing, of: self, withOffset: -16)
        subtitleLabel.autoPinEdge(.bottom, to: .bottom, of: self, withOffset: -16)
        subtitleLabel.autoSetDimension(.height, toSize: 20)
    }
    
    public static func getHeight() -> CGFloat {
        return 132
    }
}
