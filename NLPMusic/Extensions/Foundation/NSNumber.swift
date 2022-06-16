//
//  NSNumber.swift
//  VKExt
//
//  Created by programmist_NA on 20.05.2020.
//

import Foundation
import UIKit

extension Int {
    func format(f: String) -> String {
        return String(format: "%\(f)d", self)
    }
    
    var k: String {
        let numFormatter = NumberFormatter()

        typealias Abbrevation = (threshold: Double, divisor: Double, suffix: String)
        let abbreviations: [Abbrevation] = [(0, 1, ""),
                                           (1000.0, 1000.0, "K"),
                                           (100_000.0, 1_000_000.0, "M"),
                                           (100_000_000.0, 1_000_000_000.0, "B")]
                                           // you can add more !

        let startValue = Double(Swift.abs(self))
        let abbreviation: Abbrevation = {
            var prevAbbreviation = abbreviations[0]
            for tmpAbbreviation in abbreviations {
                if (startValue < tmpAbbreviation.threshold) {
                    break
                }
                prevAbbreviation = tmpAbbreviation
            }
            return prevAbbreviation
        }()

        let value = Double(self) / abbreviation.divisor
        numFormatter.positiveSuffix = abbreviation.suffix
        numFormatter.negativeSuffix = abbreviation.suffix
        numFormatter.allowsFloats = true
        numFormatter.minimumIntegerDigits = 1
        numFormatter.minimumFractionDigits = 0
        numFormatter.maximumFractionDigits = 1

        return numFormatter.string(from: NSNumber(value: value))!
    }
    
    var stringValue: String {
        return "\(self)"
    }
    
    var cgFloatValue: CGFloat {
        return CGFloat(self)
    }
    
    var floatValue: Float {
        return Float(self)
    }
    
    var doubleValue: Double {
        return Double(self)
    }
    
    var boolValue: Bool {
        switch self {
        case 1:
            return true
        case 0:
            return false
        default:
            return false
        }
    }
    
    var digitCount: Int {
        get {
            return numberOfDigits(in: self)
        }
    }
    
    func numberOfDigits(in number: Int) -> Int {
        if number < 10 && number >= 0 || number > -10 && number < 0 {
            return 1
        } else {
            return 1 + numberOfDigits(in: number / 10)
        }
    }
}
extension UInt32 {
    var stringValue: String {
        return "\(self)"
    }
}
extension Int32 {
    var stringValue: String {
        return "\(self)"
    }
}

extension Double {
    func format(f: String) -> String {
        return String(format: "%\(f)f", self)
    }
    
    func round(to places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
    
    var intValue: Int {
        return Int(self)
    }
    
    var cgFloatValue: CGFloat {
        return CGFloat(self)
    }
}
extension TimeInterval {
    var stringDuration: String {
        let time = NSInteger(self)
        
        let seconds = time % 60
        let minutes = (time / 60) % 60
        let hours = (time / 60 / 60) % 60
        
        return hours > 0 ?
            String(format: "%0.2d:%0.2d:%0.2d", hours, minutes, seconds) :
            String(format: "%0.2d:%0.2d", minutes, seconds)
    }
}
extension Float {
    func format(f: String) -> String {
        return String(format: "%\(f)f", self)
    }
}
extension CGFloat {
    func format(f: String) -> String {
        return String(format: "%\(f)f", self)
    }
    
    var doubleValue: Double {
        return Double(self)
    }
    
    var intValue: Int {
        return Int(self)
    }
}
extension String {
    var toCGFloat: CGFloat? {
      guard let doubleValue = Double(self) else { return nil }
      return CGFloat(doubleValue)
    }
}
extension CGSize {
    static var screenSize: CGSize {
        return CGSize(width: screenWidth, height: screenHeight)
    }
}
extension Bool {
    var reverseBool: Bool {
        return !self
    }
}
