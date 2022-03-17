//
//  SettingsViewController.swift
//  vkmusic
//
//  Created by Ярослав Стрельников on 04.02.2022.
//  Copyright © 2022 NP-Team. All rights reserved.
//

import Foundation
import UIKit
import AsyncDisplayKit
import Sentry
import SafariServices
import SPAlert
import SystemConfiguration
import CoreTelephony
import Foundation

enum ActionType {
    case changePlayerStyle(() -> (Void))
    case changeAccentColor(() -> (Void))
    case tgChannel(() -> (Void))
    case report(() -> (Void))
    case logout(() -> (Void))
    case cleanCache(() -> (Void))
}

enum PlayerStyle: String {
    case vk = "VK"
    case appleMusic = "Apple Music"
}

class Settings: NSObject {
    static var standartUserDefaults = UserDefaults.standard
    
    class var downloadAsPlaying: Bool {
        get {
            return standartUserDefaults.bool(forKey: "_downloadAsPlaying")
        } set {
            standartUserDefaults.set(newValue, forKey: "_downloadAsPlaying")
        }
    }
    
    class var downloadOnlyWifi: Bool {
        get {
            return standartUserDefaults.bool(forKey: "_downloadOnlyWifi")
        } set {
            standartUserDefaults.set(newValue, forKey: "_downloadOnlyWifi")
        }
    }
    
    class var smallPlayer: Bool {
        get {
            return standartUserDefaults.bool(forKey: "_smallPlayer")
        } set {
            standartUserDefaults.set(newValue, forKey: "_smallPlayer")
        }
    }
    
    class var progressDown: Bool {
        get {
            return standartUserDefaults.bool(forKey: "_progressDown")
        } set {
            standartUserDefaults.set(newValue, forKey: "_progressDown")
        }
    }
    
    class var accentColor: UInt32 {
        get {
            return standartUserDefaults.object(forKey: "_accentColor") as? UInt32 ?? 0x2979FF
        } set {
            standartUserDefaults.set(newValue, forKey: "_accentColor")
        }
    }
    
    class var clean: Void {
        return
    }
    
    class var cacheSize: String {
        return sizeOfFolder(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("music_cache").path) ?? ""
    }
    
    class var tgChannel: Void {
        return
    }
    
    class var report: Void {
        return
    }
    
    class var logout: Void {
        return
    }
    
    class var eq: Void {
        return
    }
    
    class var currentBandValues: [Float] {
        get {
            return standartUserDefaults.object(forKey: "_currentBandValues") as? [Float] ?? [4, 3, 2, 2.5, -1.5, -1.5, 0, 1, 2, 3]
        } set {
            standartUserDefaults.set(newValue, forKey: "_currentBandValues")
        }
    }
    
    class var lastPlayingIndex: Int {
        get {
            return standartUserDefaults.integer(forKey: "_lastPlayingIndex")
        } set {
            standartUserDefaults.set(newValue, forKey: "_lastPlayingIndex")
        }
    }
    
    class var lastPlayingTime: TimeInterval {
        get {
            return standartUserDefaults.double(forKey: "_lastPlayingTime")
        } set {
            standartUserDefaults.set(newValue, forKey: "_lastPlayingTime")
        }
    }
    
    class var lastProgress: Float {
        get {
            return standartUserDefaults.float(forKey: "_lastProgress")
        } set {
            standartUserDefaults.set(newValue, forKey: "_lastProgress")
        }
    }
    
    class var colorPickerElementSize: CGFloat {
        get {
            return CGFloat(standartUserDefaults.float(forKey: "_colorPickerElementSize"))
        } set {
            standartUserDefaults.set(Float(newValue), forKey: "_colorPickerElementSize")
        }
    }
    
    class func setValue(forKey key: String, value: Any) {
        standartUserDefaults.set(value, forKey: key)
    }
    
    class func build() -> [[SettingViewModel]] {
        let settings = [
            [
                SettingViewModel(title: "Стиль плеера", subtitle: smallPlayer ? "VK" : "Apple Music", setting: smallPlayer, type: .additionalText(.changePlayerStyle( { } )), key: "_smallPlayer"),
                SettingViewModel(title: "Цвет акцента (beta)", setting: String(format: "#%02X", accentColor), type: .anotherView, key: "_accentColor"),
            ],
            [
                SettingViewModel(title: "Автоскачивание", setting: downloadAsPlaying, type: .switch, key: "_downloadAsPlaying"),
                SettingViewModel(title: "Скачивать только через Wi-Fi", setting: downloadOnlyWifi, type: .switch, key: "_downloadOnlyWifi"),
                SettingViewModel(title: "Очистить кэш", setting: clean, type: .action(.cleanCache({ clearCache() })), key: "_clean")
            ],
            [
                SettingViewModel(title: "Телеграм канал разработчика", setting: tgChannel, type: .action(.tgChannel({ })), key: "_tgChannel", settingColor: .getAccentColor(fromType: .common)),
                SettingViewModel(title: "Сообщить о проблеме", setting: report, type: .action(.report({ })), key: "_report"),
                SettingViewModel(title: "Выход", setting: logout, type: .action(.logout({ VK.sessions.default.logOut() })), key: "_logout", settingColor: .systemRed)
            ]
        ]
        return settings
    }
}

struct SettingViewModel {
    var title: String
    var subtitle: String = ""
    var setting: Any
    var type: SettingType
    var key: String
    var settingColor: UIColor = .label
}

class ASSettingsViewController: ASBaseViewController<ASTableNode> {
    var tableNode: ASTableNode! {
        return node as? ASTableNode
    }
    
    var settings: [[SettingViewModel]] {
        return Settings.build()
    }
    
    override init() {
        if #available(iOS 13.0, *) {
            super.init(node: ASTableNode(style: .insetGrouped))
        } else {
            super.init(node: ASTableNode(style: .grouped))
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableNode()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        title = "Настройки"
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "Музыка", style: .done, target: nil, action: nil)
        
        if Settings.colorPickerElementSize == 0 {
            Settings.colorPickerElementSize = 10
        }
    }
    
    func setupTableNode() {
        view.addSubnode(node)
        tableNode.delegate = self
        tableNode.dataSource = self
    }
}

extension ASSettingsViewController: ASTableDataSource, ASTableDelegate {
    func numberOfSections(in tableNode: ASTableNode) -> Int {
        settings.count
    }
    
    func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        settings[section].count
    }
    
    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        let nodeBlock: ASCellNodeBlock = { [self] in
            let node = ASSettingCellNode(settings[indexPath.section][indexPath.row])
            node.delegate = self
            return node
        }
        return nodeBlock
    }
    
    func tableNode(_ tableNode: ASTableNode, constrainedSizeForRowAt indexPath: IndexPath) -> ASSizeRange {
        let size = CGSize(width: tableNode.view.contentSize.width, height: 44)
        return .init(min: size, max: size)
    }
    
    func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        tableNode.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 32
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case 0: return nil
        case 1: return "Размер кэша: \(Settings.cacheSize)"
        case 2:
            let bundle = Bundle.main
            let versionNumber = bundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
            let buildNumber = bundle.infoDictionary?[kCFBundleVersionKey as String] as? String ?? "1.0"
            return "NLP Music \(versionNumber) (\(buildNumber)) - beta"
        default: return nil
        }
    }
}

extension ASSettingsViewController: ASSettingActionDelegate {
    func didChangeSetting(_ node: ASSettingCellNode, forKey key: String, value: Bool) {
        switch node.type {
        case .plain, .action(_), .additionalText, .anotherView:
            break
        case .switch:
            switch key {
            case "_progressDown":
                UIView.transition(.promise, with: view, duration: 0.2) {
                    self.tabBarController?.popupBar.progressViewStyle = !value ? .top : .bottom
                    self.tabBarController?.popupBar.layoutIfNeeded()
                }
            default: break
            }
            Settings.setValue(forKey: key, value: value)
        }
    }
    
    func didTap(_ node: ASSettingCellNode) {
        switch node.type {
        case .switch, .plain:
            break
        case .additionalText(let action):
            switch action {
            case .changePlayerStyle(_):
                let menu = MenuViewController()
                menu.actionDelegate = self
                menu.actions = [
                    [
                        AudioItemAction(actionDescription: "vkStyle", title: PlayerStyle.vk.rawValue, action: { _ in
                            self.changePlayerStyle(menu, .vk)
                        }),
                        AudioItemAction(actionDescription: "appleMusicStyle", title: PlayerStyle.appleMusic.rawValue, action: { _ in
                            self.changePlayerStyle(menu, .appleMusic)
                        })
                    ]
                ]
                
                ContextMenu.shared.show(
                    sourceViewController: self,
                    viewController: menu,
                    options: ContextMenu.Options(
                        containerStyle: ContextMenu.ContainerStyle(
                            backgroundColor: .contextColor
                        ),
                        menuStyle: .default,
                        hapticsStyle: .medium,
                        position: .centerX
                    ),
                    sourceView: node.view,
                    delegate: nil
                )
            default: break
            }
        case .anotherView:
            DispatchQueue.main.async { [self] in
                let colorPickerViewController = CustomColorPickerViewController()
                colorPickerViewController.delegate = self
                colorPickerViewController.selectedColor = .color(from: Settings.accentColor)
                presentPanModal(colorPickerViewController)
            }
        case .action(let action):
            switch action {
            case .changePlayerStyle(_):
                let menu = MenuViewController()
                menu.actionDelegate = self
                menu.actions = [
                    [
                        AudioItemAction(actionDescription: "vkStyle", title: PlayerStyle.vk.rawValue, action: { _ in
                            self.changePlayerStyle(menu, .vk)
                        }),
                        AudioItemAction(actionDescription: "appleMusicStyle", title: PlayerStyle.appleMusic.rawValue, action: { _ in
                            self.changePlayerStyle(menu, .appleMusic)
                        })
                    ]
                ]
                
                ContextMenu.shared.show(
                    sourceViewController: self,
                    viewController: menu,
                    options: ContextMenu.Options(
                        containerStyle: ContextMenu.ContainerStyle(
                            backgroundColor: .contextColor
                        ),
                        menuStyle: .default,
                        hapticsStyle: .medium,
                        position: .centerX
                    ),
                    sourceView: node.view,
                    delegate: nil
                )
            case .tgChannel(_):
                guard let url = URL(string: "https://t.me/+d_Vk18opzow0MTky") else { return }
                let config = SFSafariViewController.Configuration()
                
                config.barCollapsingEnabled = true
                config.entersReaderIfAvailable = true
                
                let safariViewController = SFSafariViewController(url: url, configuration: config)
                present(safariViewController, animated: true)
            case .report(_):
                DispatchQueue.main.async { [self] in
                    let controller = TroubleSenderViewController()
                    presentPanModal(controller)
                }
            case .changeAccentColor(_):
                break
            case .logout(let void):
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "Выход", message: "Выйти из аккаунта?", preferredStyle: .alert)
                    
                    let confrim = UIAlertAction(title: "Выйти", style: .destructive) { _ in
                        void()
                    }
                    
                    let cancel = UIAlertAction(title: "Отмена", style: .cancel) { _ in
                        alert.dismiss(animated: true)
                    }
                    
                    alert.addAction(confrim)
                    alert.addAction(cancel)
                    
                    self.present(alert, animated: true)
                }
            case .cleanCache(let void):
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "Очистка кэша", message: "Удалить всю сохраненную музыку?", preferredStyle: .alert)
                    
                    let confrim = UIAlertAction(title: "Удалить", style: .destructive) { _ in
                        void()
                    }
                    
                    let cancel = UIAlertAction(title: "Отмена", style: .cancel) { _ in
                        alert.dismiss(animated: true)
                    }
                    
                    alert.addAction(confrim)
                    alert.addAction(cancel)
                    
                    self.present(alert, animated: true)
                }
            }
        }
    }
    
    private func changePlayerStyle(_ menu: MenuViewController, _ style: PlayerStyle) {
        switch style {
        case .vk:
            Settings.smallPlayer = true
            Settings.progressDown = true
        case .appleMusic:
            Settings.smallPlayer = false
            Settings.progressDown = false
        }
        tableNode.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .fade)
        menu.dismiss(animated: true)
    }
}

extension ASSettingsViewController: AudioItemActionDelegate {
    func didSaveAudio(_ item: AudioPlayerItem) {
        ContextMenu.shared.dismiss()
        
        do {
            try item.downloadAudio()
        } catch {
            print(error)
        }
    }
    
    func didRemoveAudio(_ item: AudioPlayerItem) {
        ContextMenu.shared.dismiss()
        
        do {
            try item.removeAudio()
        } catch {
            print(error)
        }
    }
}

extension ASSettingsViewController: HSBColorPickerDelegate, ColorPickerDelegate {
    func colorPicker(_ controller: CustomColorPickerViewController?, selectedColor: UIColor, usingControl: ColorControl) {
        controller?.colorSelectButton.backgroundColor = selectedColor
        
        let saturation: CGFloat = selectedColor.getSaturation()
        controller?.colorSelectButton.titleLabel?.textColor = saturation < 0.3 ? .black : .white
    }

    func colorPicker(_ controller: CustomColorPickerViewController?, confirmedColor: UIColor, usingControl: ColorControl) {
        Settings.setValue(forKey: "_accentColor", value: confirmedColor.hex)
        // controller?.dismiss(animated: true)

        UIView.transition(.promise, with: view, duration: 0.2) {
            self.tableNode.performBatchUpdates {
                self.tableNode.reloadData()
            }

            UINavigationBar.appearance().tintColor = .getAccentColor(fromType: .common)
            
            self.tabBarController?.popupBar.progressView.progressTintColor = .getAccentColor(fromType: .common)
            self.tabBarController?.view.layoutIfNeeded()
        }
    }
    
    func HSBColorColorPickerPanoramed(sender: HSBColorPicker, color: UIColor, point: CGPoint, state: UIGestureRecognizer.State) {
        
    }
    
    func HSBColorColorPickerTouched(sender: HSBColorPicker, color: UIColor, point: CGPoint, state: UIGestureRecognizer.State) {
        Settings.setValue(forKey: "_accentColor", value: color.hex)
        sender.parentViewController?.dismiss(animated: true)
        
        UIView.transition(.promise, with: view, duration: 0.2) {
            self.tableNode.performBatchUpdates {
                self.tableNode.reloadData()
            }

            self.asdk_navigationViewController?.navigationBar.tintColor = .getAccentColor(fromType: .common)
            self.asdk_navigationViewController?.popupBar.progressView.progressTintColor = .getAccentColor(fromType: .common)
            self.asdk_navigationViewController?.view.layoutIfNeeded()
        }
    }
}

struct SettingModel {
    var title: String
    var setting: Any
    var type: SettingType
    var key: String
    var color: UIColor
}

internal protocol HSBColorPickerDelegate: NSObjectProtocol {
    func HSBColorColorPickerTouched(sender: HSBColorPicker, color: UIColor, point: CGPoint, state: UIGestureRecognizer.State)
    func HSBColorColorPickerPanoramed(sender: HSBColorPicker, color: UIColor, point: CGPoint, state: UIGestureRecognizer.State)
}

@IBDesignable
class HSBColorPicker: UIView {

    weak internal var delegate: HSBColorPickerDelegate?
    let saturationExponentTop: Float = 2.0
    let saturationExponentBottom: Float = 1.3
    
    var colorView: UIView = {
        $0.backgroundColor = .clear
        return $0
    }(UIView())

    @IBInspectable var elementSize: CGFloat = 1.0 {
        didSet {
            setNeedsDisplay()
        }
    }

    private func initialize() {
        self.clipsToBounds = true
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(panColor(gestureRecognizer:)))
        addGestureRecognizer(panGesture)
        
        colorView.add(to: self)
        colorView.autoSetDimensions(to: .identity(48))
        colorView.drawBorder(24, width: 0.5, color: .adaptableBorder)
        colorView.isHidden = true
    }

   override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }

    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        for y : CGFloat in stride(from: 0.0 ,to: rect.height, by: elementSize) {
            var saturation = y < rect.height / 2.0 ? CGFloat(2 * y) / rect.height : 2.0 * CGFloat(rect.height - y) / rect.height
            saturation = CGFloat(powf(Float(saturation), y < rect.height / 2.0 ? saturationExponentTop : saturationExponentBottom))
            let brightness = y < rect.height / 2.0 ? CGFloat(1.0) : 2.0 * CGFloat(rect.height - y) / rect.height
            for x : CGFloat in stride(from: 0.0 ,to: rect.width, by: elementSize) {
                let hue = x / rect.width
                let color = UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1.0)
                context!.setFillColor(color.cgColor)
                context!.fill(CGRect(x: x, y: y, width:elementSize,height:elementSize))
            }
        }
    }

    func getColorAtPoint(point: CGPoint) -> UIColor {
        var fixedPoint = point
        
        if point.x > frame.maxX {
            fixedPoint.x = frame.maxX
        } else if point.x < frame.minX {
            fixedPoint.x = frame.minX
        } else {
            fixedPoint.x = point.x
        }
        
        if point.y > frame.maxY {
            fixedPoint.y = frame.maxY
        } else if point.y < frame.minY {
            fixedPoint.y = frame.minY
        } else {
            fixedPoint.y = point.y
        }
        
        let roundedPoint = CGPoint(x: elementSize * CGFloat(Int(fixedPoint.x / elementSize)),
                                   y: elementSize * CGFloat(Int(fixedPoint.y / elementSize)))
        var saturation = roundedPoint.y < self.bounds.height / 2.0 ? CGFloat(2 * roundedPoint.y) / self.bounds.height
        : 2.0 * CGFloat(self.bounds.height - roundedPoint.y) / self.bounds.height
        saturation = CGFloat(powf(Float(saturation), roundedPoint.y < self.bounds.height / 2.0 ? saturationExponentTop : saturationExponentBottom))
        let brightness = roundedPoint.y < self.bounds.height / 2.0 ? CGFloat(1.0) : 2.0 * CGFloat(self.bounds.height - roundedPoint.y) / self.bounds.height
        let hue = roundedPoint.x / self.bounds.width
        return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1.0)
    }

    func getPointForColor(color: UIColor) -> CGPoint {
        var hue: CGFloat = 0.0
        var saturation: CGFloat = 0.0
        var brightness: CGFloat = 0.0
        color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: nil);

        var yPos:CGFloat = 0
        let halfHeight = (self.bounds.height / 2)
        if (brightness >= 0.99) {
            let percentageY = powf(Float(saturation), 1.0 / saturationExponentTop)
            yPos = CGFloat(percentageY) * halfHeight
        } else {
            //use brightness to get Y
            yPos = halfHeight + halfHeight * (1.0 - brightness)
        }
        let xPos = hue * self.bounds.width
        return CGPoint(x: xPos, y: yPos)
    }
    
    @objc func panColor(gestureRecognizer: UIPanGestureRecognizer) {
        let point = gestureRecognizer.location(in: self)
        let color = getColorAtPoint(point: point)

        switch gestureRecognizer.state {
        case .began:
            colorView.isHidden = false
        case .changed:
            var colorViewPoint = point
            
            if point.x < 72 {
                colorViewPoint.x = point.x + 72
            } else if point.x > frame.maxX - 72 {
                colorViewPoint.x = point.x - 72
            } else {
                colorViewPoint.x = point.x
            }
            
            if point.y < 72 {
                colorViewPoint.y = point.y + 72
            } else {
                colorViewPoint.y = point.y - 72
            }
            
            colorView.backgroundColor = color

            UIView.transition(with: colorView, duration: 0.2, options: [.preferredFramesPerSecond60, .allowUserInteraction, .beginFromCurrentState]) { [weak self] in
                self?.colorView.frame.origin = colorViewPoint
            }

            delegate?.HSBColorColorPickerPanoramed(sender: self, color: color, point: point, state: .changed)
        case .ended:
            colorView.isHidden = true
            delegate?.HSBColorColorPickerTouched(sender: self, color: color, point: point, state: gestureRecognizer.state)
        default: break
        }
    }
}

extension UIColor {
    var hex: UInt32 {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        getRed(&r, green: &g, blue: &b, alpha: &a)
        
        r = r.isNaN || r.isInfinite ? 0 : r
        g = g.isNaN || g.isInfinite ? 0 : g
        b = b.isNaN || b.isInfinite ? 0 : b
        
        let rgb: UInt32 = (UInt32)(r * 255) << 16 | (UInt32)(g * 255) << 8 | (UInt32)(b * 255) << 0
        
        return rgb
    }
}

enum NetworkType {
    case mobile
    case wifi
    case unknown
    case nothing
}

var connectionType: NetworkType {
    guard let reachability = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, "www.google.com") else {
        return .nothing
    }
    
    var flags = SCNetworkReachabilityFlags()
    SCNetworkReachabilityGetFlags(reachability, &flags)
    
    let isReachable = flags.contains(.reachable)
    let isWWAN = flags.contains(.isWWAN)
    
    if isReachable {
        if isWWAN {
            let networkInfo = CTTelephonyNetworkInfo()
            let carrierType = networkInfo.serviceCurrentRadioAccessTechnology
            
            guard let carrierTypeName = carrierType?.first?.value else {
                return .unknown
            }
            
            switch carrierTypeName {
            case CTRadioAccessTechnologyGPRS, CTRadioAccessTechnologyEdge, CTRadioAccessTechnologyCDMA1x:
                return .mobile
            case CTRadioAccessTechnologyLTE:
                return .mobile
            default:
                return .mobile
            }
        } else {
            return .wifi
        }
    } else {
        return .nothing
    }
}

extension UIColor {
    func getSaturation() -> CGFloat {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        _ = getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        
        return saturation
    }
}
