//
//  SharedService.swift
//  Extended Messenger
//
//  Created by Ярослав Стрельников on 16.01.2021.
//

import Foundation
import UIKit
import AudioToolbox

enum Vibration {
    case error
    case success
    case warning
    case light
    case medium
    case heavy
    @available(iOS 13.0, *)
    case soft
    @available(iOS 13.0, *)
    case rigid
    case selection
    case oldSchool

    public func vibrate() {
        switch self {
        case .error:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .warning:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .light:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .medium:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .heavy:
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        case .soft:
            if #available(iOS 13.0, *) {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            }
        case .rigid:
            if #available(iOS 13.0, *) {
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            }
        case .selection:
            UISelectionFeedbackGenerator().selectionChanged()
        case .oldSchool:
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
        }
    }
}

class SharedService: NSObject {
    static let instance: SharedService = SharedService()
    
    let dateFormatter: DateFormatter = {
        let dt = DateFormatter()
        dt.locale = Locale(identifier: "ru_RU")
        dt.dateFormat = "d MMM 'в' HH:mm"
        return dt
    }()
    
    func postDate(with date: Date) -> DateFormatter {
        let currentTime: NSNumber = NSNumber(value: Date().timeIntervalSince1970)
        let timestamp: NSNumber = NSNumber(value: date.timeIntervalSince1970)
        
        let dt = DateFormatter()
        dt.locale = Locale(identifier: "ru_RU")
        
        if timestamp.doubleValue < currentTime.doubleValue && timestamp.doubleValue > currentTime.doubleValue - 86399 {
            dt.dateFormat = "Сегодня 'в' HH:mm"
            return dt
        } else if timestamp.doubleValue < currentTime.doubleValue - 86399 && timestamp.doubleValue > currentTime.doubleValue - 172799 {
            dt.dateFormat = "Вчера 'в' HH:mm"
            return dt
        } else {
            dt.dateFormat = "d MMM 'в' HH:mm"
            return dt
        }
    }
    
    func messageDate(with date: Date) -> DateFormatter {
        let currentTime: NSNumber = NSNumber(value: Date().timeIntervalSince1970)
        let timestamp: NSNumber = NSNumber(value: date.timeIntervalSince1970)
        
        let dt = DateFormatter()
        dt.locale = Locale(identifier: "ru_RU")
        
        if timestamp.doubleValue < currentTime.doubleValue && timestamp.doubleValue > currentTime.doubleValue - 86399 {
            dt.dateFormat = "HH:mm"
            return dt
        } else if timestamp.doubleValue < currentTime.doubleValue - 86399 && timestamp.doubleValue > currentTime.doubleValue - 172799 {
            dt.dateFormat = "Вчера"
            return dt
        } else {
            dt.dateFormat = "d MMM"
            return dt
        }
    }
    
    func onlineTime(with date: Date) -> DateFormatter {
        let dt = DateFormatter()
        dt.locale = Locale(identifier: "ru_RU")
        
        let elapsedTime = Date().timeIntervalSince(date)
        let hours = floor(elapsedTime / 60 / 60).intValue
        let minutes = floor((elapsedTime - (hours.doubleValue * 60 * 60)) / 60).intValue
        let seconds = floor((elapsedTime - (minutes.doubleValue * 60))).intValue

        if elapsedTime < 15 {
            dt.dateFormat = "в сети только что"
            return dt
        } else if elapsedTime < 60 {
            dt.dateFormat = "'в сети \(seconds) \(getStringByDeclension(number: Int(seconds), arrayWords: Localization.timeSeconds)) назад'"
            return dt
        } else if elapsedTime < 3600 {
            dt.dateFormat = "'в сети \(minutes) \(getStringByDeclension(number: Int(minutes), arrayWords: Localization.timeMinutes)) назад'"
            return dt
        } else if elapsedTime < 18000 {
            dt.dateFormat = "'в сети \(hours) \(getStringByDeclension(number: Int(hours), arrayWords: Localization.timeHours)) назад'"
            return dt
        } else if elapsedTime < 86399 {
            dt.dateFormat = "'в сети сегодня в' HH:mm"
            return dt
        } else if elapsedTime < 172799 {
            dt.dateFormat = "'в сети вчера в' HH:mm"
            return dt
        } else {
            dt.dateFormat = "'в сети' d MMMM 'в' HH:mm"
            return dt
        }
    }
}
