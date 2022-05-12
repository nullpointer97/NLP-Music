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
}
