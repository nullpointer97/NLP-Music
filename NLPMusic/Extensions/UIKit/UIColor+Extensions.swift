//
//  UIColor+Extensions.swift
//  ExtendedKit
//
//  Created by Ярослав Стрельников on 19.10.2020.
//

import Foundation
import UIKit

public enum AccentColorType {
    case button
    case secondaryButton
    case common
}

struct ExtendedColors {
    static let white = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1)
    static let smoke = UIColor(red: 0.97, green: 0.97, blue: 0.97, alpha: 1)
    static let lightGray = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1)
    static let gray = UIColor(red: 0.94, green: 0.94, blue: 0.94, alpha: 1)
    static let grayVK = #colorLiteral(red: 0.6823529412, green: 0.7176470588, blue: 0.7607843137, alpha: 1)
    static let middleGray = #colorLiteral(red: 0, green: 0.1098039216, blue: 0.2392156863, alpha: 0.0515036387)
    static let darkGray = UIColor(red: 0.92, green: 0.92, blue: 0.92, alpha: 1)
    static let smokeBlue = #colorLiteral(red: 0.6823529412, green: 0.7176470588, blue: 0.7607843137, alpha: 1)
    static let metal = UIColor(red: 0.71, green: 0.71, blue: 0.71, alpha: 1)
    static let dark = UIColor(red: 0.55, green: 0.55, blue: 0.55, alpha: 1)
    static let black = UIColor.color(from: 0x1f1f1f)
    static let darkGrape = UIColor(red: 0.2, green: 0.2, blue: 0.27, alpha: 1)
    static let grape = UIColor(red: 0.22, green: 0.23, blue: 0.3, alpha: 1)
    static let sea = UIColor(red: 0.15, green: 0.45, blue: 0.66, alpha: 1)
    static let sapphire = UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1)
    static let blue = UIColor.color(from: 0x3F8AE0)
    static let green = UIColor.color(from: 0x12a953)
    static let yellow = UIColor(red: 1.0, green: 0.87, blue: 0.35, alpha: 1)
    static let orange = UIColor(red: 1.0, green: 0.67, blue: 0.2, alpha: 1)
    static let red = UIColor(red: 1.0, green: 0.42, blue: 0.39, alpha: 1)
    static let space = UIColor.color(from: 0x262626)
    static let secondary = UIColor.color(from: 0x8A96B4)
}

extension UIColor {
    var isLight: Bool {
        var white: CGFloat = 0
        getWhite(&white, alpha: nil)
        return white > 0.5
    }
    
    var inverted: UIColor {
        var r: CGFloat = 0.0, g: CGFloat = 0.0, b: CGFloat = 0.0, a: CGFloat = 0.0
        UIColor.red.getRed(&r, green: &g, blue: &b, alpha: &a)
        return UIColor(red: (1 - r), green: (1 - g), blue: (1 - b), alpha: a)
    }
    
    class func color(from hex: UInt32) -> UIColor {
        let red = CGFloat((hex & 0xFF0000) >> 16) / 256.0
        let green = CGFloat((hex & 0xFF00) >> 8) / 256.0
        let blue = CGFloat(hex & 0xFF) / 256.0
        return UIColor(red: red, green: green, blue: blue, alpha: 1.0)
    }
    
    class var adaptableTextPrimaryColor: UIColor {
        if #available(iOS 13, *) {
        return UIColor { (UITraitCollection: UITraitCollection) -> UIColor in
            switch UITraitCollection.userInterfaceStyle {
            case .unspecified:
                return ExtendedColors.white
            case .light:
                return ExtendedColors.space
            case .dark:
                return ExtendedColors.white
            @unknown default:
                return ExtendedColors.space
            }
        }
        } else {
            return ExtendedColors.space
        }
    }
    
    class var adaptableTextSecondaryColor: UIColor {
        if #available(iOS 13, *) {
            return UIColor { (UITraitCollection: UITraitCollection) -> UIColor in
                switch UITraitCollection.userInterfaceStyle {
                case .dark:
                    return UIColor.color(from: 0xEBEBF5).withAlphaComponent(0.6)
                case .light:
                    return UIColor.color(from: 0x3C3C43).withAlphaComponent(0.6)
                default:
                    return UIColor.color(from: 0x3C3C43).withAlphaComponent(0.6)
                }
            }
        } else {
            return UIColor.color(from: 0x3C3C43).withAlphaComponent(0.6)
        }
    }
    
    class var adaptablePostColor: UIColor {
        if #available(iOS 13, *) {
            return UIColor { (UITraitCollection: UITraitCollection) -> UIColor in
                switch UITraitCollection.userInterfaceStyle {
                case .unspecified:
                    return .color(from: 0x161617)
                case .light:
                    return .color(from: 0xF5F5F5)
                case .dark:
                    return .color(from: 0x161617)
                @unknown default:
                    return .color(from: 0xF5F5F5)
                }
            }
        } else {
            return .color(from: 0xF5F5F5)
        }
    }

    class var adaptableWhite: UIColor {
        if #available(iOS 13, *) {
            return UIColor { (UITraitCollection: UITraitCollection) -> UIColor in
                if UITraitCollection.userInterfaceStyle == .dark {
                    return ExtendedColors.black
                } else {
                    return ExtendedColors.white
                }
            }
        } else {
            return ExtendedColors.white
        }
    }
    
    class var adaptableSeparator: UIColor {
        if #available(iOS 13, *) {
            return UIColor { (UITraitCollection: UITraitCollection) -> UIColor in
                if UITraitCollection.userInterfaceStyle == .dark {
                    return #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.1235145246)
                } else {
                    return #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.1205160651)
                }
            }
        } else {
            return #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.1213413292)
        }
    }
    
    class var adaptableField: UIColor {
        if #available(iOS 13, *) {
            return UIColor { (UITraitCollection: UITraitCollection) -> UIColor in
                if UITraitCollection.userInterfaceStyle == .dark {
                    return UIColor.black.withAlphaComponent(0.12)
                } else {
                    return color(from: 0xF2F3F5)
                }
            }
        } else {
            return color(from: 0xF2F3F5)
        }
    }
    
    class var adaptableTextView: UIColor {
        if #available(iOS 13, *) {
            return UIColor { (UITraitCollection: UITraitCollection) -> UIColor in
                if UITraitCollection.userInterfaceStyle == .dark {
                    return .color(from: 0x2C2D2E)
                } else {
                    return #colorLiteral(red: 0.9098039216, green: 0.9215686275, blue: 0.9333333333, alpha: 1)
                }
            }
        } else {
            return #colorLiteral(red: 0.9098039216, green: 0.9215686275, blue: 0.9333333333, alpha: 1)
        }
    }
    
    class var adaptableBorder: UIColor {
        if #available(iOS 13, *) {
            return UIColor { (UITraitCollection: UITraitCollection) -> UIColor in
                if UITraitCollection.userInterfaceStyle == .dark {
                    return UIColor.white.withAlphaComponent(0.12)
                } else {
                    return UIColor.black.withAlphaComponent(0.12)
                }
            }
        } else {
            return UIColor.black.withAlphaComponent(0.12)
        }
    }
    
    class var adaptableError: UIColor {
        if #available(iOS 13, *) {
            return UIColor { (UITraitCollection: UITraitCollection) -> UIColor in
                if UITraitCollection.userInterfaceStyle == .dark {
                    return .color(from: 0x522E2E)
                } else {
                    return .color(from: 0xFAEBEB)
                }
            }
        } else {
            return .color(from: 0xFAEBEB)
        }
    }
    
    class var extendedSmoke: UIColor {
        return ExtendedColors.smoke
    }
    
    class var adaptableLightGray: UIColor {
        return ExtendedColors.lightGray
    }
    
    class var extendedGray: UIColor {
        return ExtendedColors.gray
    }
    
    class var adaptableGrayVK: UIColor {
        if #available(iOS 13, *) {
            return UIColor { (UITraitCollection: UITraitCollection) -> UIColor in
                if UITraitCollection.userInterfaceStyle == .dark {
                    return UIColor.color(from: 0x818C99)
                } else {
                    return ExtendedColors.grayVK
                }
            }
        } else {
            return ExtendedColors.grayVK
        }
    }
    
    class var adaptableDarkGrayVK: UIColor {
        return UIColor.color(from: 0x818C99)
    }
    
    class var extendedPlaceholderText: UIColor {
        if #available(iOS 13, *) {
            return UIColor { traitCollection in
                return .color(from: traitCollection.userInterfaceStyle == .dark ? 0xEBEBF5 : 0x3C3C43).withAlphaComponent(0.6)
            }
        } else {
            return .color(from: 0x3C3C43).withAlphaComponent(0.6)
        }
    }
    
    class var extendedDarkGray: UIColor {
        return ExtendedColors.darkGray
    }
    
    class var adaptableSmokeBlue: UIColor {
        if #available(iOS 13, *) {
            return UIColor { (UITraitCollection: UITraitCollection) -> UIColor in
                if UITraitCollection.userInterfaceStyle == .dark {
                    return .color(from: 0x2C2D2E)
                } else {
                    return .color(from: 0xE1E3E6)
                }
            }
        } else {
            return .color(from: 0xE1E3E6)
        }
    }
    
    class var extendedMetal: UIColor {
        return ExtendedColors.metal
    }
    
    class var extendedDark: UIColor {
        return ExtendedColors.dark
    }
    
    class var adaptableBlack: UIColor {
        if #available(iOS 13, *) {
            return UIColor { (UITraitCollection: UITraitCollection) -> UIColor in
                if UITraitCollection.userInterfaceStyle == .dark {
                    return ExtendedColors.white
                } else {
                    return ExtendedColors.black
                }
            }
        } else {
            return ExtendedColors.black
        }
    }
    
    class var secondBlack: UIColor {
        if #available(iOS 13, *) {
            return UIColor { (UITraitCollection: UITraitCollection) -> UIColor in
                if UITraitCollection.userInterfaceStyle == .dark {
                    return ExtendedColors.white
                } else {
                    return .black
                }
            }
        } else {
            return .black
        }
    }
    
    open class var secondarySystemFill: UIColor {
        if #available(iOS 13, *) {
            return UIColor { (UITraitCollection: UITraitCollection) -> UIColor in
                if UITraitCollection.userInterfaceStyle == .dark {
                    return .color(from: 0x787880).withAlphaComponent(0.32)
                } else {
                    return .color(from: 0x787880).withAlphaComponent(0.16)
                }
            }
        } else {
            return .color(from: 0x787880).withAlphaComponent(0.16)
        }
    }
    
    open class var primaryPopupFill: UIColor {
        if #available(iOS 13, *) {
            return UIColor { (UITraitCollection: UITraitCollection) -> UIColor in
                if UITraitCollection.userInterfaceStyle == .dark {
                    return .color(from: 0x1c1c1e)
                } else {
                    return .color(from: 0xF2F2F7)
                }
            }
        } else {
            return .color(from: 0xF2F2F7)
        }
    }
    
    open class var secondaryPopupFill: UIColor {
        if #available(iOS 13, *) {
            return UIColor { (UITraitCollection: UITraitCollection) -> UIColor in
                if UITraitCollection.userInterfaceStyle == .dark {
                    return .color(from: 0xEBEBF5).withAlphaComponent(0.30)
                } else {
                    return .color(from: 0x3C3C43).withAlphaComponent(0.33)
                }
            }
        } else {
            return .color(from: 0x3C3C43).withAlphaComponent(0.33)
        }
    }
    
    open class var secondaryButton: UIColor {
        if #available(iOS 13, *) {
            return UIColor { (UITraitCollection: UITraitCollection) -> UIColor in
                if UITraitCollection.userInterfaceStyle != .dark {
                    return .color(from: 0x001C3D).withAlphaComponent(0.05)
                } else {
                    return .color(from: 0xFFFFFF).withAlphaComponent(0.15)
                }
            }
        } else {
            return .color(from: 0x001C3D).withAlphaComponent(0.05)
        }
    }
    
    class var insetTableView: UIColor {
        if #available(iOS 13, *) {
            return UIColor { (UITraitCollection: UITraitCollection) -> UIColor in
                if UITraitCollection.userInterfaceStyle == .dark {
                    return .black
                } else {
                    return .color(from: 0xf2f1f6)
                }
            }
        } else {
            return .color(from: 0xf2f1f6)
        }
    }
    
    class var cellBackground: UIColor {
        if #available(iOS 13, *) {
            return UIColor { (UITraitCollection: UITraitCollection) -> UIColor in
                if UITraitCollection.userInterfaceStyle == .dark {
                    return .color(from: 0x1c1c1e)
                } else {
                    return .color(from: 0xffffff)
                }
            }
        } else {
            return .color(from: 0xffffff)
        }
    }
    
    open class var systemBackground: UIColor {
        if #available(iOS 13, *) {
            return UIColor { traitCollection in
                return .color(from: traitCollection.userInterfaceStyle == .dark ? 0x000000 : 0xFFFFFF)
            }
        } else {
            return .color(from: 0xFFFFFF)
        }
    }
    
    open class var systemPlaceholder: UIColor {
        if #available(iOS 13, *) {
            return UIColor { traitCollection in
                return .color(from: traitCollection.userInterfaceStyle == .dark ? 0x202020 : 0xf8f9fb)
            }
        } else {
            return .color(from: 0xf8f9fb)
        }
    }
    
    open class var label: UIColor {
        if #available(iOS 13, *) {
            return UIColor { traitCollection in
                return .color(from: traitCollection.userInterfaceStyle != .dark ? 0x161616 : 0xFAFAFA)
            }
        } else {
            return .color(from: 0x161616)
        }
    }
    
    open class var secondaryLabel: UIColor {
        if #available(iOS 13, *) {
            return UIColor { traitCollection in
                return .color(from: traitCollection.userInterfaceStyle == .dark ? 0xEBEBF5 : 0x3C3C43).withAlphaComponent(0.6)
            }
        } else {
            return .color(from: 0x3C3C43).withAlphaComponent(0.6)
        }
    }
    
    class var musicBg: UIColor {
        if #available(iOS 13, *) {
            return UIColor { (UITraitCollection: UITraitCollection) -> UIColor in
                if UITraitCollection.userInterfaceStyle == .dark {
                    return .color(from: 0x1E1E1E).withAlphaComponent(0.75)
                } else {
                    return .color(from: 0xFAFAFA)
                }
            }
        } else {
            return .color(from: 0xFAFAFA)
        }
    }
    
    class var extendedDarkGrape: UIColor {
        return ExtendedColors.darkGrape
    }
    
    class var extendedGrape: UIColor {
        return ExtendedColors.grape
    }
    
    class var extendedSea: UIColor {
        return ExtendedColors.sea
    }
    
    class var adaptableDivider: UIColor {
        if #available(iOS 13, *) {
            return UIColor { (UITraitCollection: UITraitCollection) -> UIColor in
                if UITraitCollection.userInterfaceStyle == .dark {
                    return .color(from: 0xEBEBF5)
                } else {
                    return .color(from: 0x3C3C43)
                }
            }
        } else {
            return .color(from: 0x3C3C43)
        }
    }
    
    class var contextColor: UIColor {
        if #available(iOS 13, *) {
            return UIColor { (UITraitCollection: UITraitCollection) -> UIColor in
                if UITraitCollection.userInterfaceStyle == .dark {
                    return .color(from: 0x252525).withAlphaComponent(0.5)
                } else {
                    return .color(from: 0xEDEDED).withAlphaComponent(0.8)
                }
            }
        } else {
            return .color(from: 0xEDEDED).withAlphaComponent(0.8)
        }
    }
    
    //252525
    
    class var adaptableCard: UIColor {
        if #available(iOS 13, *) {
            return UIColor { (UITraitCollection: UITraitCollection) -> UIColor in
                if UITraitCollection.userInterfaceStyle == .dark {
                    return .color(from: 0x232323)
                } else {
                    return .color(from: 0xf2f3f5)
                }
            }
        } else {
            return .color(from: 0xf2f3f5)
        }
    }
    
    class var extendedSapphire: UIColor {
        return ExtendedColors.sapphire
    }
    
    class var extendedBlue: UIColor {
        return ExtendedColors.blue
    }
    
    class var adaptableBlue: UIColor {
        if #available(iOS 13, *) {
            return UIColor { (UITraitCollection: UITraitCollection) -> UIColor in
                if UITraitCollection.userInterfaceStyle == .dark {
                    return ExtendedColors.white
                } else {
                    return ExtendedColors.blue
                }
            }
        } else {
            return ExtendedColors.blue
        }
    }
    
    class var adaptableBackground: UIColor {
        if #available(iOS 13, *) {
            return UIColor { (UITraitCollection: UITraitCollection) -> UIColor in
                if UITraitCollection.userInterfaceStyle == .dark {
                    return .color(from: 0x2c2d2e)
                } else {
                    return UIColor.color(from: 0xF2F3F5)
                }
            }
        } else {
            return UIColor.color(from: 0xF2F3F5)
        }
    }
    
    class var adaptableButtonColor: UIColor {
        if #available(iOS 13, *) {
            return UIColor { (UITraitCollection: UITraitCollection) -> UIColor in
                if UITraitCollection.userInterfaceStyle == .dark {
                    return UIColor.color(from: 0x2c2d2f)
                } else {
                    return UIColor.color(from: 0xf1f2f4)
                }
            }
        } else {
            return UIColor.color(from: 0xf1f2f4)
        }
    }
    
    class var adaptableMutedButtonColor: UIColor {
        if #available(iOS 13, *) {
            return UIColor { (UITraitCollection: UITraitCollection) -> UIColor in
                if UITraitCollection.userInterfaceStyle == .dark {
                    return .color(from: 0x232325)
                } else {
                    return UIColor.color(from: 0xf8f8f8)
                }
            }
        } else {
            return UIColor.color(from: 0xf8f8f8)
        }
    }
    
    class var extendedGreen: UIColor {
        return ExtendedColors.green
    }
    
    class var extendedYellow: UIColor {
        return ExtendedColors.yellow
    }
    
    class var extendedOrange: UIColor {
        return ExtendedColors.orange
    }
    
    class var extendedSpace: UIColor {
        return ExtendedColors.space
    }
    
    class var adaptableOrange: UIColor {
        return .color(from: 0xFFA000)
    }
    
    class var adaptableViolet: UIColor {
        if #available(iOS 13, *) {
            return UIColor { (UITraitCollection: UITraitCollection) -> UIColor in
                if UITraitCollection.userInterfaceStyle == .dark {
                    return .color(from: 0xA393F5)
                } else {
                    return .color(from: 0x792EC0)
                }
            }
        } else {
            return .color(from: 0x792EC0)
        }
    }
    
    class var extendedRed: UIColor {
        .color(from: 0xFAEBEB)
    }
    
    class var bar: UIColor {
        return .white
    }
    
    class var barColor: UIColor {
        if #available(iOS 13, *) {
            return UIColor { (UITraitCollection: UITraitCollection) -> UIColor in
                if UITraitCollection.userInterfaceStyle == .dark {
                    return .color(from: 0x1f1f1f)
                } else {
                    return .color(from: 0xf1f1f1)
                }
            }
        } else {
            return .color(from: 0x1f1f1f)
        }
    }
    
    class var extendedBackgroundRed: UIColor {
        .color(from: 0xE64646)
    }
    
    public static var random: UIColor {
        srandom(arc4random())
        var red: Double = 0
        
        while (red < 0.1 || red > 0.84) {
            red = drand48()
        }
        
        var green: Double = 0
        while (green < 0.1 || green > 0.84) {
            green = drand48()
        }
        
        var blue: Double = 0
        while (blue < 0.1 || blue > 0.84) {
            blue = drand48()
        }
        
        return .init(red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: 1.0)
    }
    
    public static func colorHash(name: String?) -> UIColor {
        guard let name = name else {
            return .red
        }
        
        var nameValue = 0
        for character in name {
            let characterString = String(character)
            let scalars = characterString.unicodeScalars
            nameValue += Int(scalars[scalars.startIndex].value)
        }
        
        var r = Float((nameValue * 123) % 51) / 51
        var g = Float((nameValue * 321) % 73) / 73
        var b = Float((nameValue * 213) % 91) / 91
        
        let defaultValue: Float = 0.84
        r = min(max(r, 0.1), defaultValue)
        g = min(max(g, 0.1), defaultValue)
        b = min(max(b, 0.1), defaultValue)
        
        return .init(red: CGFloat(r), green: CGFloat(g), blue: CGFloat(b), alpha: 1.0)
    }
}

public enum ColorType {
    case white
    case black
    case secondBlack
    case gray
    case darkGray
    case divider
    case blue
    case lightBlack
}

public extension UIColor {
    class func messageColor(has out: Bool, has shadow: Bool = false) -> UIColor {
        //454647
        if #available(iOS 13, *) {
            return UIColor { (UITraitCollection: UITraitCollection) -> UIColor in
                if out {
                    return UITraitCollection.userInterfaceStyle == .dark ? .color(from: 0x454647) : .color(from: shadow ? 0x9ACAFF : 0xCCE4FF)
                } else {
                    return UITraitCollection.userInterfaceStyle == .dark ? .color(from: 0x2C2D2E) : .color(from: shadow ? 0xCBCCCE : 0xEBEDF0)
                }
            }
        } else {
            if out {
                return .color(from: 0xCCE4FF)
            } else {
                return .color(from: 0xEBEDF0)
            }
        }
    }
    
    class func getThemeableColor(fromNormalColor color: ColorType) -> UIColor {
        switch color {
        case .white:
            return .adaptableWhite
        case .black:
            return .adaptableBlack
        case .secondBlack:
            return .secondBlack
        case .gray:
            return .adaptableGrayVK
        case .darkGray:
            return .adaptableDarkGrayVK
        case .divider:
            return .adaptableDivider
        case .blue:
            return .adaptableBlue
        case .lightBlack:
            return .barColor
        }
    }
    
    class func getAccentColor(fromType type: AccentColorType) -> UIColor {
        switch type {
        case .button:
            return .color(from: 0x2787f5)
        case .secondaryButton:
            return .color(from: 0x0066D5)
        case .common:
            return .color(from: Settings.accentColor)
        }
    }
    
    class func getTraitCollectionChangedAccentColor(fromType type: AccentColorType) -> UIColor {
        switch type {
        case .button:
            return .color(from: 0x2787f5)
        case .secondaryButton:
            return .color(from: 0x0066D5)
        case .common:
            if #available(iOS 13, *) {
                return UIColor { (UITraitCollection: UITraitCollection) -> UIColor in
                    return UITraitCollection.userInterfaceStyle == .dark ? .white : .color(from: Settings.accentColor)
                }
            } else {
                return .color(from: Settings.accentColor)
            }
        }
    }
    
    class var searchColor: UIColor {
        if #available(iOS 13, *) {
            return UIColor { (UITraitCollection: UITraitCollection) -> UIColor in
                return UITraitCollection.userInterfaceStyle == .dark ? .color(from: 0x363738) : .color(from: 0xEBEDF0)
            }
        } else {
            return .color(from: 0xEBEDF0)
        }
    }
}
extension UIColor {
    struct Themeable {
        static var dynamicBlue: UIColor {
            return .color(from: 0x3F8AE0)
        }
        
        static var dynamicGray: UIColor {
            return .color(from: 0xA3ADB8)
        }
        
        static var dynamicRed: UIColor {
            return .color(from: 0xff3347)
        }
        
        static var dynamicGreen: UIColor {
            return .color(from: 0x4BB34B)
        }
        
        static var dynamicOrange: UIColor {
            return .color(from: 0xFFA000)
        }
        
        static var dynamicViolet: UIColor {
            if #available(iOS 13, *) {
                return UIColor { (UITraitCollection: UITraitCollection) -> UIColor in
                    if UITraitCollection.userInterfaceStyle == .dark {
                        return .color(from: 0xA393F5)
                    } else {
                        return .color(from: 0x792EC0)
                    }
                }
            } else {
                return .color(from: 0x792EC0)
            }
        }
    }
}
internal extension UIColor {
}
