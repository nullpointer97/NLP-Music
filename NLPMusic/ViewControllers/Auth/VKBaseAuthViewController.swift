//
//  VKBaseAuthViewController.swift
//  vkmusic
//
//  Created by Ярослав Стрельников on 07.03.2022.
//  Copyright © 2022 NP-Team. All rights reserved.
//

import Foundation
import UIKit
import SPAlert
import MBProgressHUD

class VKBaseAuthViewController: VKBaseViewController {
    var hud: MBProgressHUD {
        MBProgressHUD.showAdded(to: view, animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func auth(login: String, password: String, isNeedCaptchaData: Bool = false, captchaSid: String? = nil, captchaKey: String? = nil) {
        guard !login.isEmpty, !password.isEmpty else { return }
        
        hud.mode = .indeterminate

        if let captchaKey = captchaKey, let captchaSid = captchaSid {
            VK.sessions.default.logIn(login: login, password: password, captchaSid: captchaSid, captchaKey: captchaKey) { [weak self] in
                guard let self = self else { return }
                self.observeSuccess()
            } onError: { [weak self] (error) in
                guard let self = self else { return }
                self.observeError(error: error)
            }
            return
        }
        
        VK.sessions.default.logIn(login: login, password: password) { [weak self] in
            guard let self = self else { return }
            self.observeSuccess()
        } onError: { [weak self] (error) in
            guard let self = self else { return }
            self.observeError(error: error)
        }
    }

    func observeSuccess() {
        DispatchQueue.main.async {
            self.hud.hide(animated: true)
            
            guard let window = self.view.window else { return }
            window.isHeroEnabled = true
            window.hero.modifiers = [.fade]
            
            let transition = CATransition()
            transition.type = .push
            transition.subtype = .fromTop
            
            let rootViewController = VKTabController()
            
            window.rootViewController = rootViewController
            
            window.layer.add(transition, forKey: kCATransition)
        }
    }
    
    func observeError(error: VKError, isNeedCaptchaData: Bool = false) {
        hud.hide(animated: true)
    }
}
