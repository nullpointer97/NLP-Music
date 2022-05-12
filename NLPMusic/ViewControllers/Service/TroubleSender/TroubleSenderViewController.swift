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

class TroubleSenderViewController: NLPModalViewController {
    @IBOutlet weak var dismissButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var sendReportButton: UIButton!
    @IBOutlet weak var reportTextView: UITextView!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var troubleDecription: UILabel!
    
    var popupHeightWithoutKeyboard: CGFloat {
        return 211 + (UIDevice.current.hasNotch ? 24 : 8)
    }
    
    var popupHeightWithKeyboard: CGFloat {
        return 211 + (UIDevice.current.hasNotch ? 335 : 260) + (UIDevice.current.hasNotch ? 24 : 8)
    }
    
    var isKeyboard = false
    
    override var longFormHeight: PanModalHeight {
        return .contentHeightIgnoringSafeArea(popupHeightWithKeyboard)
    }
    
    override var shortFormHeight: PanModalHeight {
        return .contentHeightIgnoringSafeArea(popupHeightWithoutKeyboard)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupObservers()
        
        view.backgroundColor = .systemBackground.withAlphaComponent(0.1)
        view.setBlurBackground(style: .regular)
        
        titleLabel.text = .localized(.report)
        
        dismissButton.setTitle("", for: .normal)
        dismissButton.backgroundColor = .secondaryPopupFill.withAlphaComponent(0.2)
        dismissButton.drawBorder(15, width: 0)
        
        reportTextView.delegate = self
        reportTextView.backgroundColor = .adaptableField
        reportTextView.drawBorder(10, width: 1, color: .getAccentColor(fromType: .common))

        sendReportButton.backgroundColor = .getAccentColor(fromType: .common)
        
        troubleDecription.text = .localized(.trouble)
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

    @IBAction func dismissPopup(_ sender: UIButton) {
        dismiss(animated: true)
    }

    @IBAction func sendReport(_ sender: UIButton) {
        guard let message = reportTextView.text, !message.isEmpty else { return }
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
        guard UIDevice.current.userInterfaceIdiom != .pad, let params = notification.keyboardParams else { return }
        bottomConstraint.constant = params.height
        
        UIView.animate(withDuration: params.animationDuration, delay: 0, options: params.animationOptions) { [weak self] in
            self?.view.layoutIfNeeded()
        }
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        guard UIDevice.current.userInterfaceIdiom != .pad, let params = notification.keyboardParams else { return }
        bottomConstraint.constant = 12

        UIView.animate(withDuration: params.animationDuration, delay: 0, options: params.animationOptions) { [weak self] in
            self?.view.layoutIfNeeded()
        }
    }
    
    private func updateLayout() {
//        updateViewConstraints()
        panModalSetNeedsLayoutUpdate()
    }
}

extension TroubleSenderViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        textView.drawBorder(10, width: 1, color: .getAccentColor(fromType: .common), isAnimated: true)
        if textView.text == "Опишите проблему" {
            textView.text = nil
            textView.textColor = .label
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        textView.drawBorder(10, width: 1, color: .adaptableBorder, isAnimated: true)
        if textView.text.isEmpty {
            textView.text = "Опишите проблему"
            textView.textColor = .secondaryLabel
        }
        
        if textView.text.isEmpty || textView.text.count >= 3 {
            textView.backgroundColor = .adaptableField
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        guard let message = textView.text else {
            changeButtonAlpha(false)
            return
        }
        textView.drawBorder(10, width: 1, color: message.count >= 3 ? .getAccentColor(fromType: .common) : .systemRed, isAnimated: true)
        textView.backgroundColor = message.count >= 3 ? .adaptableField : .systemRed.withAlphaComponent(0.2)
        changeButtonAlpha(message.count >= 3)
    }
}

extension Notification {
    var keyboardParams: KeyboardParams? {
        guard let userInfo = self.userInfo,
              let animationDuration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
              let height = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height,
              let curveValue = (userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber)?.uintValue
        else { return nil }
        let curveAnimationOptions = UIView.AnimationOptions(rawValue: curveValue << 16)
        
        let keyboardParams = KeyboardParams(animationDuration: animationDuration, height: height, animationOptions: curveAnimationOptions)

        return keyboardParams
    }
}

struct KeyboardParams {
    var animationDuration: TimeInterval
    var height: CGFloat
    var animationOptions: UIView.AnimationOptions
}

extension Date {
    static func currentDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.YYYY, HH:mm:ss"
        formatter.timeZone = .autoupdatingCurrent
        return formatter.string(from: Date())
    }
}
