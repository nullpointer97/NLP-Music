//
//  AppDelegate.swift
//  vkmusic
//
//  Created by Ярослав Стрельников on 26.01.2022.
//

import UIKit
import OneSignal
import Sentry
import SwiftyJSON
import AVKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    private var delegate: ExtendedVKDelegate?
    var window: UIWindow?
    private var observables: [Observable] = []

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        delegate = VKGeneralDelegate()
        UIViewController.swizzle()

        SentrySDK.start { options in
            options.dsn = "https://7943a0ef5b054de089558bd3d6132c24@o1097085.ingest.sentry.io/6190479"
            options.debug = false
            options.enableAutoPerformanceTracking = false
            options.tracesSampleRate = 1.0
        }
        
        setWindow()
        
        application.beginReceivingRemoteControlEvents()

        AudioService.instance.startPlayer()
        
        OneSignal.setLogLevel(.LL_VERBOSE, visualLevel: .LL_NONE)
        
        OneSignal.initWithLaunchOptions(launchOptions)
        OneSignal.setAppId("198db6ad-618f-4531-99cb-3574d1df6f1b")

        OneSignal.promptForPushNotifications(userResponse: { accepted in
            print("User accepted notifications: \(accepted)")
        })
        
        UNUserNotificationCenter.current().delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(audioRouteChangeListener(_:)), name: AVAudioSession.routeChangeNotification, object: nil)
        
        return true
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if let custom = userInfo["custom"] as? [AnyHashable: Any] {
            if let a = custom["a"] as? [AnyHashable: Any], let appLock = a["app_locked"] as? String {
                UserDefaults.standard.set(appLock.boolValue, forKey: "_isAppLocked")
            }
        }
    }
    
    private func setWindow() {
        if #available(iOS 13.0, *) { } else {
            let rootViewController = VK.sessions.default.state == .authorized ? VKTabController() : VKMNavigationController(rootViewController: LoginViewController())
            
            window = UIWindow(frame: UIScreen.main.bounds)
            window?.rootViewController = rootViewController
            window?.makeKeyAndVisible()
        }
    }
    
    @objc func onLogout() {
        setWindow()
    }
    
    @objc private func audioRouteChangeListener(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue:reasonValue) else {
                  return
              }
        switch reason {
        case .newDeviceAvailable:
            let session = AVAudioSession.sharedInstance()
            
            for output in session.currentRoute.outputs where output.portType == .headphones || output.portType == .bluetoothA2DP || output.portType == .carAudio || output.portType == .usbAudio {
                UNUserNotificationCenter.sendNotification()
                break
            }
        default: ()
        }
    }
}

extension Data {
    func parse() -> String {
        map { data in String(format: "%02.2hhx", data) }.joined()
    }
}

@available(iOS 13.0, *)
extension AppDelegate {
    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if notification.request.content.categoryIdentifier == "HEADPHONE_NOTIFICATION" {
            completionHandler([.alert])
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [notification.request.identifier])
            }
        } else {
            completionHandler([.sound, .alert, .badge])
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if response.notification.request.content.categoryIdentifier == "HEADPHONE_NOTIFICATION" {
            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [response.notification.request.identifier])
            completionHandler()
        }
    }
}

extension UNUserNotificationCenter {
    static func sendNotification() {
        guard let headphoneMessagesJSON = Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: nil)?.filter({ $0.lastPathComponent == "headphone_messages.json" }).first else { return }
        
        var items: [JSON] = []
        
        do {
            let string = try Data(contentsOf: headphoneMessagesJSON)
            items = JSON(string)["response"]["items"].arrayValue
        } catch {
            print(error)
            return
        }
        
        guard let randomItem = items.randomElement() else { return }
        
        let notificationCenter = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        let headphoneNotifications = "HEADPHONE_NOTIFICATION"

        content.categoryIdentifier = headphoneNotifications
        content.title = randomItem["title"].stringValue
        content.subtitle = randomItem["subtitle"].stringValue
        
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .active
        }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let identifier = "local"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        notificationCenter.add(request) { (error) in
            if let error = error {
                print("Error \(error)")
            }
        }
        let category = UNNotificationCategory(identifier: headphoneNotifications,
                                              actions: [],
                                              intentIdentifiers: [],
                                              options: [.hiddenPreviewsShowTitle, .hiddenPreviewsShowSubtitle])
        
        notificationCenter.setNotificationCategories([category])
    }
}
