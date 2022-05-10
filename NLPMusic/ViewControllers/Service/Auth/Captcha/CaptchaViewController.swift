//
//  CaptchaViewController.swift
//  vkExtended
//
//  Created by Ярослав Стрельников on 24.10.2020.
//

import UIKit
import Kingfisher
import AsyncDisplayKit

class CaptchaViewController: VKBaseAuthViewController {
    @IBOutlet weak var capthcaImageView: UIImageView!
    @IBOutlet weak var captchaEnterTextField: UITextField!
    @IBOutlet weak var reauthButton: UIButton!

    var login: String
    var password: String
    
    init(captchaUrl: String, captchaSid: String, login: String, password: String) {
        self.login = login
        self.password = password
        
        super.init(nibName: "CaptchaViewController", bundle: nil)

        self.captchaSid = captchaSid
        self.captchaImg = captchaUrl
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Re-Captcha"

        reauthButton.setCorners(radius: 8)
        reauthButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        reauthButton.backgroundColor = .getThemeableColor(fromNormalColor: .black)
        
        reauthButton.backgroundColor = .getAccentColor(fromType: .common)
        reauthButton.setTitleColor(.white, for: .normal)
        
        captchaEnterTextField.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        captchaEnterTextField.keyboardType = .default
        
        capthcaImageView.kf.setImage(with: URL(string: captchaImg))
    }
    
    @IBAction func reAuthAction(_ sender: UIButton) {
        auth(login: login, password: password, isNeedCaptchaData: true, captchaSid: captchaSid, captchaKey: captchaEnterTextField.text)
        print("auth:", captchaSid)
        print("auth:", captchaEnterTextField.text)
    }
    
    override func observeError(error: VKError, isNeedCaptchaData: Bool = false) {
        super.observeError(error: error, isNeedCaptchaData: isNeedCaptchaData)
        switch error {
        case .needCaptcha(let captchaImg, let captchaSid):
            self.captchaImg = captchaImg
            self.captchaSid = captchaSid
            DispatchQueue.main.async {
                self.capthcaImageView.kf.setImage(with: URL(string: captchaImg))
            }
        default: break
        }
    }
}
