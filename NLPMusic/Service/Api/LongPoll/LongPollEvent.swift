import Foundation
import SwiftyJSON

/// Represents LongPoll event. More info - https://vk.com/dev/using_longpoll
public enum LongPollEvent {
    case forcedStop
    case historyMayBeLost
    case event1(_ json: JSON)
    case event2(_ json: JSON)
    case event3(_ json: JSON)
    case event4(_ json: JSON)
    case event5(_ json: JSON)
    case event6(_ json: JSON)
    case event7(_ json: JSON)
    case event8(_ json: JSON)
    case event9(_ json: JSON)
    case event10(_ json: JSON)
    case event11(_ json: JSON)
    case event12(_ json: JSON)
    case event13(_ json: JSON)
    case event14(_ json: JSON)
    case event20(_ json: JSON)
    case event21(_ json: JSON)
    case event51(_ json: JSON)
    case event52(_ json: JSON)
    case event61(_ json: JSON)
    case event62(_ json: JSON)
    case event70(_ json: JSON)
    case event80(_ json: JSON)
    case event114(_ json: JSON)
    
    // swiftlint:disable cyclomatic_complexity next
    init?(json: JSON) {
        guard let event = json.array?.first?.int else { return nil }
        
        switch event {
        case 1:
            self = .event1(json)
        case 2:
            self = .event2(json)
        case 3:
            self = .event3(json)
        case 4:
            self = .event4(json)
        case 6:
            self = .event6(json)
        case 5:
            self = .event5(json)
        case 7:
            self = .event7(json)
        case 8:
            self = .event8(json)
        case 9:
            self = .event9(json)
        case 10:
            self = .event10(json)
        case 11:
            self = .event11(json)
        case 12:
            self = .event12(json)
        case 13:
            self = .event13(json)
        case 14:
            self = .event14(json)
        case 20:
            self = .event20(json)
        case 21:
            self = .event21(json)
        case 51:
            self = .event51(json)
        case 52:
            self = .event52(json)
        case 61:
            self = .event61(json)
        case 62:
            self = .event62(json)
        case 70:
            self = .event70(json)
        case 80:
            self = .event80(json)
        case 114:
            self = .event114(json)
        default:
            return nil
        }
    }
}

extension JSON {
    func data(_ path: String) -> Data? {
        let anyValue: Any? = path
        
        guard anyValue is NSArray || anyValue is NSDictionary else {
            return nil
        }
        
        return try? JSONSerialization.data(withJSONObject: anyValue as Any, options: [])
    }
}
func string(from object: Any) -> String? {
    guard let data = try? JSONSerialization.data(withJSONObject: object, options: []) else {
        return nil
    }
    return String(data: data, encoding: .utf8)
}
