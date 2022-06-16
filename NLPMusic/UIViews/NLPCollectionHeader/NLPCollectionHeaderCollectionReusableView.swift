//
//  NLPCollectionHeaderCollectionReusableView.swift
//  NLPMusic
//
//  Created by Ярослав Стрельников on 15.05.2022.
//  Copyright © 2022 NP-Team. All rights reserved.
//

import UIKit
import Kingfisher

class NLPCollectionHeaderCollectionReusableView: UICollectionReusableView {
    private var imageView = UIImageView()
    private var separatorView = UIView()
    private var titleLabel = UILabel()
    private var showAllButton = UIButton()
    var artistLabel = UILabel()
    
    var title: String? {
        get { return titleLabel.text }
        set {
            titleLabel.text = newValue
            titleLabel.hideSkeleton()
        }
    }
    
    var artistName: String? {
        get { return artistLabel.text }
        set {
            artistLabel.text = newValue
            artistLabel.hideSkeleton()
        }
    }
    
    var attributedTitle: NSAttributedString? {
        get { return NSAttributedString(string: titleLabel.text ?? "") }
        set {
            titleLabel.attributedText = newValue
            titleLabel.hideSkeleton()
        }
    }
    
    var image: UIImage? {
        get { return imageView.image }
        set { imageView.image = newValue }
    }
    
    var imageUrl: String? = nil {
        didSet {
            if let url = URL(string: imageUrl), image == nil {
                KingfisherManager.shared.retrieveImage(with: url) { result in
                    switch result {
                    case .success(let value):
                        DispatchQueue.main.async {
                            self.imageView.image = value.image.applyBlurWithRadius(self.isNeedBlur ? 15 : 0, tintColor: .black.withAlphaComponent(0.35), saturationDeltaFactor: 1.8)
                        }
                    case .failure(let err):
                        print(err)
                    }
                }
            }
        }
    }
    
    var isNeedShowAll: Bool = true {
        didSet {
            showAllButton.isHidden = !isNeedShowAll
        }
    }
    
    var isNeedBlur: Bool = true
    
    var isNeedSeparator: Bool = true {
        didSet {
            separatorView.isHidden = !isNeedSeparator
        }
    }
    
    var isNeedImage: Bool = true {
        didSet {
            imageView.isHidden = !isNeedImage
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
        imageView.add(to: self)
        separatorView.add(to: self)
        showAllButton.add(to: self)
        titleLabel.add(to: self)
        artistLabel.add(to: imageView)
        
        imageView.autoPinEdge(.top, to: .top, of: self)
        imageView.autoPinEdge(.leading, to: .leading, of: self, withOffset: -16)
        imageView.autoPinEdge(.trailing, to: .trailing, of: self, withOffset: 16)
        imageView.autoPinEdge(.bottom, to: .bottom, of: self, withOffset: -46)
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        
        artistLabel.autoPinEdge(.bottom, to: .bottom, of: imageView, withOffset: -16)
        artistLabel.autoPinEdge(.leading, to: .leading, of: imageView, withOffset: 16)
        artistLabel.autoPinEdge(.trailing, to: .trailing, of: imageView, withOffset: -16)
        artistLabel.font = .systemFont(ofSize: 20, weight: .black)
        artistLabel.textColor = .systemBackground
        
        separatorView.autoPinEdge(.top, to: .top, of: self)
        separatorView.autoPinEdge(.leading, to: .leading, of: self)
        separatorView.autoPinEdge(.trailing, to: .trailing, of: self)
        separatorView.autoSetDimension(.height, toSize: 0.5)
        separatorView.backgroundColor = .adaptableBorder
        
        showAllButton.autoPinEdge(.trailing, to: .trailing, of: self)
        showAllButton.autoPinEdge(.bottom, to: .bottom, of: self)
        showAllButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .regular)
        showAllButton.setTitle("Показать все", for: .normal)
        showAllButton.setTitleColor(.getAccentColor(fromType: .common), for: .normal)
        showAllButton.autoSetDimensions(to: .custom(96, 44))
        
        titleLabel.autoPinEdge(.leading, to: .leading, of: self)
        titleLabel.autoPinEdge(.trailing, to: .leading, of: showAllButton, withOffset: -12)
        titleLabel.autoPinEdge(.bottom, to: .bottom, of: self, withOffset: -9)
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = .label
    }
}
