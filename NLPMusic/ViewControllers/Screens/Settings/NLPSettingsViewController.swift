//
//  SettingsViewController.swift
//  vkmusic
//
//  Created by Ярослав Стрельников on 04.02.2022.
//  Copyright © 2022 NP-Team. All rights reserved.
//

import Foundation
import UIKit
import Sentry
import SafariServices
import SPAlert
import SystemConfiguration
import CoreTelephony
import Foundation
import MaterialComponents

enum ActionType {
    case changePlayerStyle(() -> (Void))
    case changeDismissType(() -> (Void))
    case changeAccentColor(() -> (Void))
    case tgChannel(() -> (Void))
    case donate(() -> (Void))
    case report(() -> (Void))
    case logout(() -> (Void))
    case cleanCache(() -> (Void))
    case update(() -> (Void))
}

enum PlayerStyle: String {
    case vk = "VK"
    case appleMusic = "Apple Music"
    case nlp = "NLP Music"
    
    static func style(for int: Int) -> Self {
        switch int {
        case 1: return .vk
        case 2: return .nlp
        default: return .appleMusic
        }
    }
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
    
    class var playerStyle: Int {
        get {
            return standartUserDefaults.integer(forKey: "_playerStyle")
        } set {
            standartUserDefaults.set(newValue, forKey: "_playerStyle")
        }
    }
    
    class var namesInTabbar: Bool {
        get {
            return standartUserDefaults.bool(forKey: "_namesInTabbar")
        } set {
            standartUserDefaults.set(newValue, forKey: "_namesInTabbar")
        }
    }
    
    class var progressDown: Bool {
        get {
            return standartUserDefaults.bool(forKey: "_progressDown")
        } set {
            standartUserDefaults.set(newValue, forKey: "_progressDown")
        }
    }
    
    class var dismissType: Int {
        get {
            return standartUserDefaults.integer(forKey: "_dismissType")
        } set {
            standartUserDefaults.set(newValue, forKey: "_dismissType")
        }
    }
    
    class var accentColor: UInt32 {
        get {
            return standartUserDefaults.object(forKey: "_accentColor") as? UInt32 ?? 0x2979FF
        } set {
            standartUserDefaults.set(newValue, forKey: "_accentColor")
        }
    }
    
    class var user: Void {
        return
    }
    
    class var clean: Void {
        return
    }
    
    class var update: Void {
        return
    }
    
    class var cacheSize: String {
        return sizeOfFolder(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("music_cache").path) ?? ""
    }
    
    class var cacheSizeInt: Int64 {
        return sizeOfFolder(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("music_cache").path)
    }
    
    class var tgChannel: Void {
        return
    }
    
    class var donate: Void {
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
                SettingViewModel(title: "", subtitle: "", setting: Settings.user, type: .plain, key: "_user", isEnabled: true, image: nil, user: nil)
            ],
            [
                SettingViewModel(title: "Стиль плеера", subtitle: PlayerStyle.style(for: playerStyle).rawValue, setting: playerStyle, type: .additionalText(.changePlayerStyle( { } )), key: "_playerStyle", image: "palette_outline_16", imageColor: .color(from: 0xFF9500)),
                SettingViewModel(title: "Цвет акцента", setting: String(format: "#%02X", accentColor), type: .anotherView, key: "_accentColor", image: "brush_outline_24", imageColor: .color(from: 0x007AFF)),
                SettingViewModel(title: "Сворачивание плеера", subtitle: dismissType == 0 ? "Snap" : "Interactive", setting: dismissType, type: .additionalText(.changeDismissType( { } )), key: "_playerStyle", image: "interactive_24", imageColor: .color(from: 0x007AFF)),
                SettingViewModel(title: "Подписи в таббаре", setting: namesInTabbar, type: .switch, key: "_namesInTabbar", defaultValue: true, image: "text_16", imageColor: .color(from: 0x34C759))
            ],
            [
                SettingViewModel(title: "Автоскачивание", setting: downloadAsPlaying, type: .switch, key: "_downloadAsPlaying", defaultValue: false, image: "down_16", imageColor: .color(from: 0x34C759)),
                SettingViewModel(title: "Скачивать только через Wi-Fi", setting: downloadOnlyWifi, type: .switch, key: "_downloadOnlyWifi", defaultValue: true, image: "wifi", imageColor: .color(from: 0x007AFF)),
                SettingViewModel(title: "Очистить кэш", setting: clean, type: .action(.cleanCache({ clearCache() })), key: "_clean", isEnabled: cacheSizeInt > 0, image: "clear_data_24", imageColor: .color(from: 0xFF3B30))
            ],
            [
                SettingViewModel(title: "Обновление", setting: update, type: .action(.update( { } ) ), key: "_update", isEnabled: false, image: "market_outline_16", imageColor: .color(from: 0xFF3B30))
            ],
            [
                SettingViewModel(title: "Телеграм канал разработчика", setting: tgChannel, type: .action(.tgChannel({ })), key: "_tgChannel", image: "navigation-2", imageColor: .color(from: 0x5856D6)),
                SettingViewModel(title: "Поддержать разработчика", setting: donate, type: .action(.donate({ })), key: "_donate", image: "money_transfer_24", imageColor: .color(from: 0x5856D6)),
                SettingViewModel(title: "Сообщить о проблеме", setting: report, type: .action(.report({ })), key: "_report", image: "advertising_24", imageColor: .color(from: 0x8E8E93)),
                SettingViewModel(title: "Выход", setting: logout, type: .action(.logout({ VK.sessions.default.logOut() })), key: "_logout", settingColor: .systemRed, image: "share_external_24 iOS", imageColor: .systemRed)
            ]
        ]
        return settings
    }
}

struct SettingViewModel: Hashable {
    var hashValue: Int {
        return Int(settingColor.hex)
    }
    
    var title: String
    var subtitle: String = ""
    var setting: Any
    var type: SettingType
    var key: String
    var settingColor: UIColor = .label
    var defaultValue: Bool = false
    var isEnabled: Bool = true
    var image: String?
    var imageColor: UIColor = .clear
    
    var user: NLPUser?
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(Int(settingColor.hex))
    }
    
    static func == (lhs: SettingViewModel, rhs: SettingViewModel) -> Bool {
        return lhs.key == rhs.key
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
