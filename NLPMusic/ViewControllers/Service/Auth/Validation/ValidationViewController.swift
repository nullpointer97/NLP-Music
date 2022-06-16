//
//  ValidationViewController.swift
//  vkExtended
//
//  Created by Ярослав Стрельников on 29.11.2020.
//

import UIKit
import SPAlert

class ValidationViewController: VKBaseAuthViewController {
    let login: String
    let password: String
    let phoneMask: String
    let redirectUri: String?
    
    @IBOutlet weak var twoAuthCodeTextField: OneTimeCodeTextField!
    
    var seconds = 150
    var timer = Timer()
    
    var isTimerRunning = false
    var resumeTapped = false
    
    var isError = false
    
    init(login: String, password: String, phoneMask: String, redirectUri: String?) {
        self.login = login
        self.password = password
        self.phoneMask = phoneMask
        self.redirectUri = redirectUri
        super.init(nibName: "ValidationViewController", bundle: nil)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "2FA Authentication"

        twoAuthCodeTextField.defaultCharacter = "-"
        twoAuthCodeTextField.configure()
        
        twoAuthCodeTextField.delegate = self
        
        twoAuthCodeTextField.didEnterLastDigit = { [weak self] code in
            self?.main.async {
                self?.auth(code: code, forceSms: 0)
            }
        }
    }
    
    func auth(code: String? = nil, forceSms: Int? = nil) {
        if let code = code {
            VK.sessions.default.logIn(login: login, password: password, code: code.isEmpty ? " " : code, forceSms: forceSms) { [weak self] in
                guard let self = self else { return }
                self.observeSuccess()
                /*if forceSms == 1 {
                    let text = NSAttributedString(string: "Мы отправили SMS c кодом подтверждения на номер", attributes: [.font: UIFont.systemFont(ofSize: 15, weight: .medium), .foregroundColor: UIColor.getThemeableColor(fromNormalColor: .darkGray)]) + attributedNewLine + NSAttributedString(string: self.phoneMask, attributes: [.font: UIFont.systemFont(ofSize: 15, weight: .medium), .foregroundColor: UIColor.getThemeableColor(fromNormalColor: .black)])
                    
                    self.stateLabel.attributedText = text
                    self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.updateTimer), userInfo: nil, repeats: true)
                    self.isTimerRunning = true
                }*/
            } onError: { [weak self] (error) in
                guard let self = self else { return }
                self.observeError(error: error)
            }
            return
        }
    }
    
    @objc func updateTimer() {
        if seconds < 1 {
            timer.invalidate()
        } else {
            seconds -= 1
        }
    }
    
    override func observeError(error: VKError, isNeedCaptchaData: Bool = false) {
        super.observeError(error: error, isNeedCaptchaData: isNeedCaptchaData)
        main.async {
            self.isError = true
            switch error {
            case .needValidation(validationType: let type, phoneMask: let mask, redirectUri: let uri):
                guard let uri = uri, let url = URL(string: uri) else { return }
                UIApplication.shared.open(url)
            default:
                self.twoAuthCodeTextField.setErrorCode()
            }
        }
    }
}

extension ValidationViewController: UITextFieldDelegate {
    func textFieldDidChangeSelection(_ textField: UITextField) {
        if isError && twoAuthCodeTextField.digitLabels[0].textColor == .systemRed && textField.text?.count ?? 0 < 6 {
            self.twoAuthCodeTextField.setValidCode()
        }
    }
}
