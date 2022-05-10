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
    
    override var longFormHeight: PanModalHeight {
        return .contentHeight(144)
    }
    
    override var shortFormHeight: PanModalHeight {
        return .contentHeight(144)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground.withAlphaComponent(0.1)
        view.setBlurBackground(style: .regular)
        
        dimsissButton.setTitle("", for: .normal)
        dimsissButton.backgroundColor = .secondaryPopupFill.withAlphaComponent(0.2)
        dimsissButton.drawBorder(15, width: 0)
    }

    @IBAction func dismissController(_ sender: Any) {
        dismiss(animated: true)
    }
}
