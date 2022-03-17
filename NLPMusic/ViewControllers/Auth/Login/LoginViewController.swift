//
//  LoginViewController.swift
//  Extended Messenger
//
//  Created by Ярослав Стрельников on 16.01.2021.
//

import UIKit
import SPAlert

class LoginViewController: VKBaseAuthViewController {
    @IBOutlet weak var loginTextField: UITextField!
    @IBOutlet weak var passwordTextView: UITextField!
    @IBOutlet weak var dataStackView: UIStackView!
    @IBOutlet weak var loginButton: UIButton!
    
    private let keyboardManagerService = KeyboardManagerService()
    private var isInitialLayout: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Авторизация"
        NotificationCenter.default.addObserver(self, selector: #selector(didSuccessLogin(_:)), name: .onLogin, object: nil)
        
        loginTextField.delegate = self
        passwordTextView.delegate = self
        
        if #available(iOS 13.0, *) { } else {
            loginTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
            passwordTextView.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        }
        
        loginButton.backgroundColor = .getAccentColor(fromType: .common)
        loginButton.setTitleColor(.white, for: .normal)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if isInitialLayout {
            defer {
                isInitialLayout = false
            }
            keyboardManagerService.animateWhenKeyboardAppear = { [weak self] appearPostIndex, keyboardHeight, keyboardHeightIncrement in
                if let self = self {
                    self.view.layoutIfNeeded()
                }
            }
            keyboardManagerService.animateWhenKeyboardDisappear = { [weak self] keyboardHeight in
                if let self = self {
                    self.view.layoutIfNeeded()
                }
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    override func observeError(error: VKError, isNeedCaptchaData: Bool = false) {
        super.observeError(error: error, isNeedCaptchaData: isNeedCaptchaData)
        DispatchQueue.main.async {
            guard let login = self.loginTextField.text, let password = self.passwordTextView.text, !login.isEmpty, !password.isEmpty else { return }
            switch error {
            case .needCaptcha(captchaImg: let captchaImg, captchaSid: let captchaSid):
                if isNeedCaptchaData {
                    
                } else {
                    let captchaController = CaptchaViewController(captchaUrl: captchaImg, captchaSid: captchaSid, login: login, password: password)
                    captchaController.modalPresentationStyle = .fullScreen
                    self.present(captchaController, animated: true, completion: nil)
                }
            case .incorrectLoginPassword:
                self.showEventMessage(.error, message: "Неверный логин или пароль")
            case .needValidation(validationType: let type, phoneMask: let mask, redirectUri: let uri):
                guard let login = self.loginTextField.text, let password = self.passwordTextView.text, !login.isEmpty, !password.isEmpty else { return }
                self.asdk_navigationViewController?.pushViewController(ValidationViewController(login: login, password: password, phoneMask: mask, redirectUri: uri), animated: true)
            default:
                break
            }
        }
    }
    
    @objc func didSuccessLogin(_ notification: Notification) {
        observeSuccess()
    }

    @IBAction func didTapLogin(_ sender: Any) {
        view.endEditing(true)
        guard let login = loginTextField.text, let password = passwordTextView.text, !login.isEmpty, !password.isEmpty else { return }
        auth(login: login, password: password, isNeedCaptchaData: false)
    }
}

extension LoginViewController: UITextFieldDelegate {
    func textFieldDidChangeSelection(_ textField: UITextField) {
        if passwordTextView.text?.isEmpty ?? true || loginTextField.text?.isEmpty ?? true {
            loginButton.isEnabled = false
            loginButton.alpha = 0.5
        } else {
            loginButton.isEnabled = true
            loginButton.alpha = 1
        }
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        if passwordTextView.text?.isEmpty ?? true || loginTextField.text?.isEmpty ?? true {
            loginButton.isEnabled = false
            loginButton.alpha = 0.5
        } else {
            loginButton.isEnabled = true
            loginButton.alpha = 1
        }
    }
}

import UIKit

extension UIDevice {
    var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        func mapToDevice(identifier: String) -> String {
            #if os(iOS)
            switch identifier {
            case "AudioAccessory1,1":   return "HomePod"
            case "AudioAccessory1,2":   return "HomePod"
            case "iPad1,1":             return "iPad"
            case "iPad11,1":            return "iPad mini (5th generation)"
            case "iPad11,2":            return "iPad mini (5th generation)"
            case "iPad11,3":            return "iPad Air (3rd generation)"
            case "iPad11,4":            return "iPad Air (3rd generation)"
            case "iPad11,6":            return "iPad (8th generation)"
            case "iPad11,7":            return "iPad (8th generation)"
            case "iPad13,1":            return "iPad Air (4th generation)"
            case "iPad13,2":            return "iPad Air (4th generation)"
            case "iPad2,1":             return "iPad 2"
            case "iPad2,2":             return "iPad 2"
            case "iPad2,3":             return "iPad 2"
            case "iPad2,4":             return "iPad 2"
            case "iPad2,5":             return "iPad mini"
            case "iPad2,6":             return "iPad mini"
            case "iPad2,7":             return "iPad mini"
            case "iPad3,1":             return "iPad (3rd generation)"
            case "iPad3,2":             return "iPad (3rd generation)"
            case "iPad3,3":             return "iPad (3rd generation)"
            case "iPad3,4":             return "iPad (4th generation)"
            case "iPad3,5":             return "iPad (4th generation)"
            case "iPad3,6":             return "iPad (4th generation)"
            case "iPad4,1":             return "iPad Air"
            case "iPad4,2":             return "iPad Air"
            case "iPad4,3":             return "iPad Air"
            case "iPad4,4":             return "iPad mini 2"
            case "iPad4,5":             return "iPad mini 2"
            case "iPad4,6":             return "iPad mini 2"
            case "iPad4,7":             return "iPad mini 3"
            case "iPad4,8":             return "iPad mini 3"
            case "iPad4,9":             return "iPad mini 3"
            case "iPad5,1":             return "iPad mini 4"
            case "iPad5,2":             return "iPad mini 4"
            case "iPad5,3":             return "iPad Air 2"
            case "iPad5,4":             return "iPad Air 2"
            case "iPad6,11":            return "iPad (5th generation)"
            case "iPad6,12":            return "iPad (5th generation)"
            case "iPad6,3":             return "iPad Pro (9.7-inch)"
            case "iPad6,4":             return "iPad Pro (9.7-inch)"
            case "iPad6,7":             return "iPad Pro (12.9-inch)"
            case "iPad6,8":             return "iPad Pro (12.9-inch)"
            case "iPad7,1":             return "iPad Pro (12.9-inch) (2nd generation)"
            case "iPad7,11":            return "iPad (7th generation)"
            case "iPad7,12":            return "iPad (7th generation)"
            case "iPad7,2":             return "iPad Pro (12.9-inch) (2nd generation)"
            case "iPad7,3":             return "iPad Pro (10.5-inch)"
            case "iPad7,4":             return "iPad Pro (10.5-inch)"
            case "iPad7,5":             return "iPad (6th generation)"
            case "iPad7,6":             return "iPad (6th generation)"
            case "iPad8,1":             return "iPad Pro (11-inch)"
            case "iPad8,10":            return "iPad Pro (11-inch) (2nd generation)"
            case "iPad8,11":            return "iPad Pro (12.9-inch) (4th generation)"
            case "iPad8,12":            return "iPad Pro (12.9-inch) (4th generation)"
            case "iPad8,2":             return "iPad Pro (11-inch)"
            case "iPad8,3":             return "iPad Pro (11-inch)"
            case "iPad8,4":             return "iPad Pro (11-inch)"
            case "iPad8,5":             return "iPad Pro (12.9-inch) (3rd generation)"
            case "iPad8,6":             return "iPad Pro (12.9-inch) (3rd generation)"
            case "iPad8,7":             return "iPad Pro (12.9-inch) (3rd generation)"
            case "iPad8,8":             return "iPad Pro (12.9-inch) (3rd generation)"
            case "iPad8,9":             return "iPad Pro (11-inch) (2nd generation)"
            case "iPhone1,1":           return "iPhone"
            case "iPhone1,2":           return "iPhone 3G"
            case "iPhone10,1":          return "iPhone 8"
            case "iPhone10,2":          return "iPhone 8 Plus"
            case "iPhone10,3":          return "iPhone X"
            case "iPhone10,4":          return "iPhone 8"
            case "iPhone10,5":          return "iPhone 8 Plus"
            case "iPhone10,6":          return "iPhone X"
            case "iPhone11,2":          return "iPhone XS"
            case "iPhone11,4":          return "iPhone XS Max"
            case "iPhone11,6":          return "iPhone XS Max"
            case "iPhone11,8":          return "iPhone XR"
            case "iPhone12,1":          return "iPhone 11"
            case "iPhone12,3":          return "iPhone 11 Pro"
            case "iPhone12,5":          return "iPhone 11 Pro Max"
            case "iPhone12,8":          return "iPhone SE (2nd generation)"
            case "iPhone13,1":          return "iPhone 12 mini"
            case "iPhone13,2":          return "iPhone 12"
            case "iPhone13,3":          return "iPhone 12 Pro"
            case "iPhone13,4":          return "iPhone 12 Pro Max"
            case "iPhone14,2":          return "iPhone 13 Pro"
            case "iPhone14,3":          return "iPhone 13 Pro Max"
            case "iPhone14,4":          return "iPhone 13 mini"
            case "iPhone14,5":          return "iPhone 13"
            case "iPhone2,1":           return "iPhone 3GS"
            case "iPhone3,1":           return "iPhone 4"
            case "iPhone3,2":           return "iPhone 4"
            case "iPhone3,3":           return "iPhone 4"
            case "iPhone4,1":           return "iPhone 4S"
            case "iPhone5,1":           return "iPhone 5"
            case "iPhone5,2":           return "iPhone 5"
            case "iPhone5,3":           return "iPhone 5c"
            case "iPhone5,4":           return "iPhone 5c"
            case "iPhone6,1":           return "iPhone 5s"
            case "iPhone6,2":           return "iPhone 5s"
            case "iPhone7,1":           return "iPhone 6 Plus"
            case "iPhone7,2":           return "iPhone 6"
            case "iPhone8,1":           return "iPhone 6s"
            case "iPhone8,2":           return "iPhone 6s Plus"
            case "iPhone8,4":           return "iPhone SE (1st generation)"
            case "iPhone9,1":           return "iPhone 7"
            case "iPhone9,2":           return "iPhone 7 Plus"
            case "iPhone9,3":           return "iPhone 7"
            case "iPhone9,4":           return "iPhone 7 Plus"
            case "iPod1,1":             return "iPod touch"
            case "iPod2,1":             return "iPod touch (2nd generation)"
            case "iPod3,1":             return "iPod touch (3rd generation)"
            case "iPod4,1":             return "iPod touch (4th generation)"
            case "iPod5,1":             return "iPod touch (5th generation)"
            case "iPod7,1":             return "iPod touch (6th generation)"
            case "iPod9,1":             return "iPod touch (7th generation)"
            case "i386", "x86_64":      return "Simulator \(mapToDevice(identifier: ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "iOS"))"
            default:                    return identifier
            }
            #elseif os(tvOS)
            switch identifier {
            case "AppleTV1,1":          return "Apple TV (1st generation). Number: A1218"
            case "AppleTV2,1":          return "Apple TV (2nd generation). Number: A1378"
            case "AppleTV3,1":          return "Apple TV (3rd generation). Number: A1427"
            case "AppleTV3,2":          return "Apple TV (3rd generation). Number: A1469"
            case "AppleTV5,3":          return "Apple TV (4th generation). Number: A1625"
            case "AppleTV6,2":          return "Apple TV 4K. Number: A1842"
            case "i386", "x86_64":      return "Simulator \(mapToDevice(identifier: ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "tvOS"))"
            default: return identifier
            }
            #endif
        }
        
        return mapToDevice(identifier: identifier)
    }
}
