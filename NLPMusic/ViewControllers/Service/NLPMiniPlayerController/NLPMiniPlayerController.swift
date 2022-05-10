//
//  NLPMiniPlayerController.swift
//  NLPMusic
//
//  Created by Ярослав Стрельников on 07.05.2022.
//  Copyright © 2022 NP-Team. All rights reserved.
//

import Foundation
import UIKit

class NLPMiniPlayerController: LNPopupCustomBarViewController {
    
    var artworkImageView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()
    
    var playButton: PlayButton = {
        let button = PlayButton()
        button.pauseStopBackgroundColor = .clear
        button.playBufferingBackgroundColor = .clear
        button.setMode(.stop, animated: true)
        return button
    }()
    
    override var wantsDefaultTapGestureRecognizer: Bool {
        return true
    }
    
    override var wantsDefaultPanGestureRecognizer: Bool {
        return true
    }
    
    override var wantsDefaultHighlightGestureRecognizer: Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        preferredContentSize = .init(width: screenWidth, height: 66)
        
        artworkImageView.add(to: view)
        artworkImageView.autoPinEdge(.leading, to: .leading, of: view)
        artworkImageView.autoPinEdge(.top, to: .top, of: view)
        artworkImageView.autoPinEdge(.bottom, to: .bottom, of: view)
        artworkImageView.autoAlignAxis(toSuperviewAxis: .horizontal)
        artworkImageView.autoSetDimension(.width, toSize: 66)
        
        playButton.add(to: artworkImageView)
        playButton.autoCenterInSuperview()
        playButton.autoSetDimensions(to: .identity(66))
        playButton.playBufferingTintColor = artworkImageView.image?.averageColor?.inverted ?? .label
        playButton.pauseStopTintColor = artworkImageView.image?.averageColor?.inverted ?? .label
        
        popupBar.progressViewStyle = .none
    }
    
    override func popupItemDidUpdate() {
        super.popupItemDidUpdate()
        
        artworkImageView.image = popupItem.image
        playButton.playBufferingTintColor = artworkImageView.image?.averageColor?.inverted ?? .label
        playButton.pauseStopTintColor = artworkImageView.image?.averageColor?.inverted ?? .label
    }
}
