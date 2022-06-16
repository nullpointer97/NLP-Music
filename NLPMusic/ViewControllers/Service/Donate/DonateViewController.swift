//
//  DonateViewController.swift
//  NLPMusic
//
//  Created by Ярослав Стрельников on 30.03.2022.
//  Copyright © 2022 NP-Team. All rights reserved.
//

import UIKit

class DonateViewController: NLPModalViewController {
    @IBOutlet weak var dimsissButton: UIButton!
    @IBOutlet weak var donateTextView: UITextView!
    @IBOutlet weak var titleLabel: UILabel!
    
    override var longFormHeight: PanModalHeight {
        return .contentHeight(144)
    }
    
    override var shortFormHeight: PanModalHeight {
        return .contentHeight(144)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.text = .localized(.donate)
        
        view.backgroundColor = .systemBackground.withAlphaComponent(0.1)
        view.setBlurBackground(style: .regular)
        
        dimsissButton.setTitle("", for: .normal)
        dimsissButton.backgroundColor = .secondaryPopupFill.withAlphaComponent(0.2)
        dimsissButton.drawBorder(15, width: 0)
        
        donateTextView.attributedText = NSAttributedString(string: .localized(.donateDescription), attributes: [.font: UIFont.systemFont(ofSize: 16, weight: .medium), .foregroundColor: UIColor.label]) + attributedSpace + NSAttributedString(string: "2202 2032 1535 5563", attributes: [.font: UIFont.systemFont(ofSize: 17, weight: .semibold), .foregroundColor: UIColor.getAccentColor(fromType: .common)])
    }

    @IBAction func dismissController(_ sender: Any) {
        dismiss(animated: true)
    }
}
