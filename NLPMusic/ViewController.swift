//
//  ViewController.swift
//  vkmusic
//
//  Created by Ярослав Стрельников on 26.01.2022.
//

import UIKit

class ViewController: NLPBaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        createPlaceholder()
    }
    
    
    private func createPlaceholder() {
        let stackView = UIStackView()
        stackView.alignment = .center
        stackView.axis = .vertical
        stackView.spacing = 8
        
        let imageView = UIImageView()
        imageView.image = .init(named: "color-palette")?.tint(with: .label.withAlphaComponent(0.5))
        imageView.autoSetDimensions(to: .identity(72))
        
        let titleLabel = UILabel()
        titleLabel.text = "В разработке"
        titleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        titleLabel.textColor = .label.withAlphaComponent(0.5)
        titleLabel.textAlignment = .center
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = "Сейчас раздел недоступен, так как он находится в разработке"
        subtitleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        subtitleLabel.textColor = .label.withAlphaComponent(0.35)
        subtitleLabel.numberOfLines = 0
        subtitleLabel.textAlignment = .center
        
        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(subtitleLabel)
        
        stackView.add(to: view)
        stackView.autoCenterInSuperview()
        stackView.autoPinEdge(.leading, to: .leading, of: view, withOffset: 48)
        stackView.autoPinEdge(.trailing, to: .trailing, of: view, withOffset: -48)
    }
}

