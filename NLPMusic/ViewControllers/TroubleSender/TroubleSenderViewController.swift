//
//  TroubleSenderViewController.swift
//  vkmusic
//
//  Created by Ярослав Стрельников on 01.03.2022.
//  Copyright © 2022 NP-Team. All rights reserved.
//

import UIKit
import Sentry
import SPAlert

class TroubleSenderViewController: VKBaseViewController, PanModalPresentable {
    @IBOutlet weak var dismissButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var sendReportButton: UIButton!
    @IBOutlet weak var reportMessageTextField: UITextField!
    
    var popupHeightWithoutKeyboard: CGFloat {
        return 211 + (UIDevice.current.hasNotch ? 24 : 8)
    }
    
    var popupHeightWithKeyboard: CGFloat {
        return 211 + (UIDevice.current.hasNotch ? 335 : 260) + (UIDevice.current.hasNotch ? 24 : 8)
    }
    
    var panScrollable: UIScrollView? {
        return nil
    }
    
    var longFormHeight: PanModalHeight {
        return .contentHeightIgnoringSafeArea(popupHeightWithKeyboard)
    }
    
    var shortFormHeight: PanModalHeight {
        return .contentHeightIgnoringSafeArea(popupHeightWithoutKeyboard)
    }
    
    public var cornerRadius: CGFloat {
        return 16
    }
    
    public var springDamping: CGFloat {
        return 0.7
    }
    
    public var dragIndicatorBackgroundColor: UIColor {
        return .white
    }
    
    public var dragIndicatorOffset: CGFloat {
        return -16
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupObservers()
        
        view.backgroundColor = .primaryPopupFill
        
        titleLabel.text = "Отчет о проблеме"
        
        dismissButton.setTitle("", for: .normal)
        dismissButton.backgroundColor = .secondaryPopupFill.withAlphaComponent(0.2)
        dismissButton.drawBorder(15, width: 0)
        
        reportMessageTextField.delegate = self
        reportMessageTextField.addTarget(self, action: #selector(didProblemeMessageChanged(_:)), for: .valueChanged)
        
        sendReportButton.backgroundColor = .getAccentColor(fromType: .common)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        view.endEditing(true)
    }
    
    private func setupObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    private func changeButtonAlpha(_ value: Bool) {
        UIView.animate(withDuration: 0.3, delay: 0, options: [.allowUserInteraction, .beginFromCurrentState]) { [weak self] in
            self?.sendReportButton.alpha = value ? 1 : 0.5
        } completion: { [weak self] _ in
            self?.sendReportButton.isEnabled = value
        }
    }
    
    @objc func didProblemeMessageChanged(_ sender: UITextField) {
        guard let message = sender.text else {
            changeButtonAlpha(false)
            return
        }
        changeButtonAlpha(message.count >= 3)
    }

    @IBAction func dismissPopup(_ sender: UIButton) {
        dismiss(animated: true)
    }

    @IBAction func sendReport(_ sender: UIButton) {
        guard let message = reportMessageTextField.text, !message.isEmpty else { return }
        let event = Sentry.Event()
        event.message = SentryMessage(formatted: "Отчет о проблеме :vk.com/id\(currentUserId):")
        event.level = .warning
        event.user = Sentry.User(userId: "\(currentUserId)")
        event.extra = [
            "probleme_message": message,
            "user_id": currentUserId,
            "timestamp": Date.currentDate()
        ]
        
        SentrySDK.capture(event: event)
        dismiss(animated: true) {
            SPAlert.present(title: "Отправлено!", preset: .done, haptic: .success)
        }
    }
}

extension TroubleSenderViewController {
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard UIDevice.current.userInterfaceIdiom != .pad else { return }
        updateLayout()
        panModalTransition(to: .longForm)
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        guard UIDevice.current.userInterfaceIdiom != .pad else { return }
        updateLayout()
        panModalTransition(to: .shortForm)
    }
    
    private func updateLayout() {
        panModalSetNeedsLayoutUpdate()
    }
}

extension TroubleSenderViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return true
    }
}

extension Notification {
    func getKeyboardParams() -> (TimeInterval, CGFloat)? {
        guard let userInfo = self.userInfo,
              let animationDuration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
              let height = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height
        else { return nil }

        return (animationDuration, height)
    }
}

extension Date {
    static func currentDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.YYYY, HH:mm:ss"
        formatter.timeZone = .autoupdatingCurrent
        return formatter.string(from: Date())
    }
}
