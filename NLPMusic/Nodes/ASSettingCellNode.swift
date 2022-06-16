//
//  ASSettingCellNode.swift
//  vkmusic
//
//  Created by Ярослав Стрельников on 08.02.2022.
//  Copyright © 2022 NP-Team. All rights reserved.
//

import UIKit
import AsyncDisplayKit

class ASBaseNode: ASCellNode {
    var type: SettingType = .plain
}

protocol ASSettingActionDelegate: AnyObject {
    func didChangeSetting(_ node: ASSettingCellNode, forKey key: String, value: Bool)
    func didTap(_ node: ASSettingCellNode)
}

class ASSettingCellNode: ASBaseNode, ASSwitchTarget {
    let settingSwitch = ASSwitchNode()
    let settingLabel = ASTextNode()
    let additionalLabel = ASTextNode()
    let colorNode = ASDisplayNode()
    
    weak var delegate: ASSettingActionDelegate?

    override var type: SettingType {
        didSet {
            switch type {
            case .switch:
                colorNode.isHidden = true
                settingSwitch.isHidden = false
                additionalLabel.isHidden = true
            case .plain, .anotherView:
                colorNode.isHidden = false
                settingSwitch.isHidden = true
                additionalLabel.isHidden = true
            case .additionalText:
                colorNode.isHidden = true
                settingSwitch.isHidden = true
                additionalLabel.isHidden = false
            case .action(_):
                colorNode.isHidden = true
                settingSwitch.isHidden = true
                additionalLabel.isHidden = true
            }
        }
    }
    var settingKey: String = ""
    
    init(_ setting: SettingViewModel) {
        super.init()
        alpha = setting.isEnabled ? 1 : 0.5
        isUserInteractionEnabled = setting.isEnabled
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 15.5),
            .foregroundColor: setting.settingColor
        ]
        
        let secondAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 13),
            .foregroundColor: UIColor.secondaryLabel
        ]
        
        settingLabel.attributedText = NSAttributedString(string: setting.title, attributes: attributes)
        settingLabel.truncationMode = .byTruncatingTail
        settingKey = setting.key
        
        switch setting.type {
        case .plain, .action(_):
            break
        case .anotherView:
            colorNode.backgroundColor = .getAccentColor(fromType: .common)
        case .switch:
            DispatchQueue.main.async { [weak self] in
                self?.settingSwitch.isOn = setting.setting as? Bool ?? setting.defaultValue
            }
        case .additionalText:
            additionalLabel.attributedText = NSAttributedString(string: "\(setting.subtitle)", attributes: secondAttributes)
        }
        type = setting.type
        automaticallyManagesSubnodes = true
        automaticallyRelayoutOnSafeAreaChanges = true
    }
    
    override func didLoad() {
        super.didLoad()
        settingSwitch.target = self
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        didTap()
    }
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        settingLabel.maximumNumberOfLines = 1
        additionalLabel.maximumNumberOfLines = 1
        
        settingSwitch.style.preferredSize = .custom(49, 31)
        
        settingLabel.style.flexShrink = 1
        additionalLabel.style.flexShrink = 0
        
        colorNode.style.preferredSize = .custom(28, 28)
        colorNode.cornerRadius = 14
        colorNode.borderWidth = 1
        colorNode.borderColor = UIColor.adaptableBorder.cgColor
        
        let firstStack = ASStackLayoutSpec.horizontal()
        
        let firstSpacer = ASLayoutSpec()
        firstSpacer.style.width = .init(unit: .points, value: 8)

        firstStack.alignItems = .center
        firstStack.justifyContent = .start
        firstStack.style.flexShrink = 1
        firstStack.style.flexGrow = 1
        firstStack.children = [settingLabel, firstSpacer]
        
        let secondStack = ASStackLayoutSpec(direction: .horizontal, spacing: 16, justifyContent: .spaceBetween, alignItems: .center, flexWrap: .noWrap, alignContent: .center, children: [settingLabel, additionalLabel])
        secondStack.style.flexShrink = 1
        secondStack.style.flexGrow = 1
        
        if #available(iOS 13.0, *) {
            secondStack.style.preferredSize = CGSize(width: screenWidth - 64, height: 44)
        } else {
            secondStack.style.preferredSize = CGSize(width: screenWidth - 32, height: 44)
        }
        
        let thirdStack = ASStackLayoutSpec(direction: .horizontal, spacing: 16, justifyContent: .spaceBetween, alignItems: .center, flexWrap: .noWrap, alignContent: .center, children: [settingLabel, settingSwitch])
        thirdStack.style.flexShrink = 1
        secondStack.style.flexGrow = 1
        
        if #available(iOS 13.0, *) {
            thirdStack.style.preferredSize = CGSize(width: screenWidth - 64, height: 44)
        } else {
            thirdStack.style.preferredSize = CGSize(width: screenWidth - 32, height: 44)
        }
        
        let fourStack = ASStackLayoutSpec(direction: .horizontal, spacing: 16, justifyContent: .spaceBetween, alignItems: .center, flexWrap: .noWrap, alignContent: .center, children: [settingLabel, colorNode])
        fourStack.style.flexShrink = 1
        fourStack.style.flexGrow = 1
        
        if #available(iOS 13.0, *) {
            fourStack.style.preferredSize = CGSize(width: screenWidth - 64, height: 44)
        } else {
            fourStack.style.preferredSize = CGSize(width: screenWidth - 32, height: 44)
        }

        let verticalStack = ASStackLayoutSpec.horizontal()
        
        switch type {
        case .plain, .action(_):
            verticalStack.children = [
                ASInsetLayoutSpec(insets: .init(top: 0, left: 16, bottom: 0, right: 8), child: firstStack)
            ]
        case .anotherView:
            verticalStack.children = [
                ASInsetLayoutSpec(insets: .init(top: 0, left: 16, bottom: 0, right: 8), child: fourStack)
            ]
        case .switch:
            verticalStack.children = [
                ASInsetLayoutSpec(insets: .init(top: 0, left: 16, bottom: 0, right: 8), child: thirdStack)
            ]
        case .additionalText:
            verticalStack.children = [
                ASInsetLayoutSpec(insets: .init(top: 0, left: 16, bottom: 0, right: 16), child: secondStack)
            ]
        }

        verticalStack.alignContent = .center
        verticalStack.alignItems = .center
        verticalStack.justifyContent = .start
        verticalStack.style.alignSelf = .start
        verticalStack.style.flexShrink = 1
        return verticalStack
    }
    
    internal func didValueChange(_ node: ASSwitchNode, _ value: Bool) {
        onChangeSetting(value)
    }
    
    @objc func didTap() {
        delegate?.didTap(self)
    }
    
    @objc func onChangeSetting(_ value: Bool) {
        delegate?.didChangeSetting(self, forKey: settingKey, value: value)
    }
}

protocol ASSwitchTarget: AnyObject {
    func didValueChange(_ node: ASSwitchNode, _ value: Bool)
}

open class ASSwitchNode: ASDisplayNode {
    private var controlSwitch: UISwitch!
    weak var target: ASSwitchTarget?
    
    var isOn: Bool = false {
        didSet {
            DispatchQueue.main.async {
                self.controlSwitch?.isOn = self.isOn
            }
        }
    }
    
    override init() {
        super.init()
        
        style.preferredSize = .custom(49, 31)
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.controlSwitch = UISwitch()
            self.controlSwitch.onTintColor = .getAccentColor(fromType: .common)

            self.view.addSubview(self.controlSwitch)
            self.controlSwitch.autoPinEdgesToSuperviewEdges()
            self.controlSwitch.autoSetDimensions(to: .custom(49, 31))
            self.controlSwitch.addTarget(self, action: #selector(self.didValueChange(_:)), for: .valueChanged)
        }
    }
    
    @objc func didValueChange(_ sender: UISwitch) {
        target?.didValueChange(self, sender.isOn)
    }
}
