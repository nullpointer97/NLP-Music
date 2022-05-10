//
//  VKPairButtonViewCell.swift
//  NLPMusic
//
//  Created by Ярослав Стрельников on 10.03.2022.
//  Copyright © 2022 NP-Team. All rights reserved.
//

import UIKit

@objc protocol PairButtonDelegate: AnyObject {
    @objc optional func didPlayAll(_ cell: NLPPairButtonViewCell)
    @objc optional func didShuffleAll(_ cell: NLPPairButtonViewCell)
}

@objc class NLPPairButtonViewCell: UITableViewCell {
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var shuffleButton: UIButton!
    
    weak var delegate: PairButtonDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        configureLayout()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func configureLayout() {
        playButton.backgroundColor = .secondaryButton
        shuffleButton.backgroundColor = .secondaryButton
        
        playButton.setTitleColor(.getAccentColor(fromType: .common), for: .normal)
        shuffleButton.setTitleColor(.getAccentColor(fromType: .common), for: .normal)
        
        playButton.setImage(.init(named: "play.fill")?.resize(toWidth: 20)?.resize(toHeight: 20)?.tint(with: .getAccentColor(fromType: .common)), for: .normal)
        shuffleButton.setImage(.init(named: "shuffle_24")?.resize(toWidth: 20)?.resize(toHeight: 20)?.tint(with: .getAccentColor(fromType: .common)), for: .normal)
        
        playButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        shuffleButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        
        playButton.drawBorder(10, width: 0)
        shuffleButton.drawBorder(10, width: 0)
    }

    @IBAction func didPlay(_ sender: UIButton) {
        delegate?.didPlayAll?(self)
    }

    @IBAction func didShuffle(_ sender: UIButton) {
        delegate?.didShuffleAll?(self)
    }
}
