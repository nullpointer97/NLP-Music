//
//  UITableViewFooter.swift
//  vkmusic
//
//  Created by Ярослав Стрельников on 01.03.2022.
//  Copyright © 2022 NP-Team. All rights reserved.
//

import Foundation
import UIKit

open class UITableViewFooter: UIView {
    var activityIndicator: UIActivityIndicatorView = {
        $0.backgroundColor = .clear
        $0.contentMode = .scaleAspectFit
        $0.startAnimating()
        $0.color = .getAccentColor(fromType: .common)
        return $0
    }(UIActivityIndicatorView())
    
    var footerText: UILabel = {
        $0.text = ""
        $0.textAlignment = .center
        $0.textColor = .secondaryLabel
        $0.font = .systemFont(ofSize: 13, weight: .regular)
        $0.numberOfLines = 0
        return $0
    }(UILabel())
    
    public var isLoading: Bool = false {
        didSet {
            activityIndicator.isHidden = !isLoading
            if isLoading {
                activityIndicator.startAnimating()
            } else {
                activityIndicator.stopAnimating()
            }
            footerText.isHidden = isLoading
        }
    }
    
    public var loadingText: String? {
        get {
            return footerText.text
        } set {
            DispatchQueue.main.async { [weak self] in
                self?.footerText.text = newValue
            }
        }
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commomInit()
    }
    
    public init() {
        super.init(frame: .zero)
        commomInit()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commomInit()
    }
    
    func commomInit() {
        isLoading = false
        
        addSubview(activityIndicator)
        activityIndicator.autoCenterInSuperview()
        activityIndicator.autoSetDimensions(to: .init(width: 40, height: 40))
        
        addSubview(footerText)
        footerText.autoCenterInSuperview()
        footerText.autoPinEdge(.top, to: .top, of: self, withOffset: 0)
        footerText.autoPinEdge(.bottom, to: .bottom, of: self, withOffset: -12)
        footerText.autoPinEdge(.leading, to: .leading, of: self, withOffset: 12)
        footerText.autoPinEdge(.bottom, to: .bottom, of: self, withOffset: -0)
    }
}
