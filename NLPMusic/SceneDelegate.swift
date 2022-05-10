//
//  SceneDelegate.swift
//  vkmusic
//
//  Created by Ярослав Стрельников on 26.01.2022.
//

import UIKit
import MaterialComponents
import CoreStore
import SPAlert

@available(iOS 13.0, *)
var currentScene: UIScene?

@available(iOS 13.0, *)
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    var count = 0
    var timer: Timer?
    let label = UILabel()

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        let rootViewController = VK.sessions.default.state == .authorized ? NLPTabController() : NLPMNavigationController(rootViewController: LoginViewController())
        
        guard let windowScene = (scene as? UIWindowScene) else { return }
        currentScene = scene
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.windowScene = windowScene
        
        /*guard let urls = Bundle.main.urls(forResourcesWithExtension: nil, subdirectory: nil) else { return }
        if urls.count != 44 || EncryptionCheck.executableEncryption() {
            let viewController = UIViewController()
            viewController.view.backgroundColor = .systemBackground
            
            let labelView = UIView()
            labelView.backgroundColor = .clear
            labelView.add(to: viewController.view)
            labelView.autoCenterInSuperview()
            labelView.autoPinEdge(.leading, to: .leading, of: viewController.view, withOffset: 16, relation: .greaterThanOrEqual)
            labelView.autoPinEdge(.trailing, to: .trailing, of: viewController.view, withOffset: -16, relation: .greaterThanOrEqual)
            labelView.autoPinEdge(.top, to: .top, of: viewController.view, withOffset: 16, relation: .greaterThanOrEqual)
            labelView.autoPinEdge(.bottom, to: .bottom, of: viewController.view, withOffset: -16, relation: .greaterThanOrEqual)

            label.add(to: labelView)
            label.autoPinEdgesToSuperviewEdges(with: .identity(12))
            label.font = .systemFont(ofSize: 15, weight: .medium)
            label.textColor = .secondaryLabel
            label.text = "Тут ничего нет 😢"
            label.numberOfLines = 0
            label.textAlignment = .center
            label.sizeToFit()
            
            var str = "ХЪвыаывЫХУК УЦХ АуцЫА ХЫУА ДЫывА ЛЫФЗВ АОЖЫ"
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [self] in
                UIView.animate(withDuration: 0.4, delay: 0, options: [.beginFromCurrentState]) {
                    label.fadeTransition(0.4)
                    label.text = "Не надо ломать чужие приложения 🙁"
                    viewController.view.layoutIfNeeded()
                } completion: { _ in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        UIView.animate(withDuration: 0.4, delay: 0, options: [.beginFromCurrentState]) {
                            label.fadeTransition(0.4)
                            label.text = "Это очень некрасиво 🤗"
                            viewController.view.layoutIfNeeded()
                        } completion: { _ in
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                label.text = ""
                                timer = Timer.scheduledTimer(timeInterval: 0.04, target: self, selector: #selector(self.updating), userInfo: nil, repeats: true)
                            }
                        }
                    }
                }
            }
            
            window?.rootViewController = viewController
        } else {
            window?.rootViewController = rootViewController
        }*/
        window?.rootViewController = rootViewController
        window?.makeKeyAndVisible()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        try? AudioDataStackService.dataStack.perform { transaction in
            let allAudios = try transaction.fetchAll(From<AudioItem>())
            
            for audio in allAudios {
                audio.isPlaying = false
                audio.isPaused = false
            }
        }
    }
    
    @objc func updating() {
        var str = "ХЪвыаывЫХУКапиываьпдУЦХывпдлжьыыпАуцЫАЪЪЪЪЪХЫУАп35прщоцузеДЫывАвыдпльыЛЫФЗывдпвьжАОЖЫ"
        if count >= str.count - 1 {
            timer?.invalidate()
            timer = nil
            label.font = .systemFont(ofSize: 40, weight: .bold)
            label.text = "БАН!"
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                exit(0)
            }
            return
        }
        
        count += 1
        label.font = .systemFont(ofSize: CGFloat(Int.random(in: 10...35)), weight: .medium)
        label.text = "\(label.text ?? "")\(str[count])"
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }

    private func setWindow() {
        let rootViewController = VK.sessions.default.state == .authorized ? NLPTabController() : NLPMNavigationController(rootViewController: LoginViewController())
        
        window?.rootViewController = nil
        window?.rootViewController = rootViewController
        window?.makeKeyAndVisible()
    }
    
    @objc func onLogout() {
        setWindow()
    }
}

extension UIView {
    func fadeTransition(_ duration:CFTimeInterval) {
        let animation = CATransition()
        animation.timingFunction = CAMediaTimingFunction(name:
            CAMediaTimingFunctionName.easeInEaseOut)
        animation.type = CATransitionType.fade
        animation.duration = duration
        layer.add(animation, forKey: CATransitionType.fade.rawValue)
    }
}

extension StringProtocol {
    subscript(offset: Int) -> Character { self[index(startIndex, offsetBy: offset)] }
    subscript(range: Range<Int>) -> SubSequence {
        let startIndex = index(self.startIndex, offsetBy: range.lowerBound)
        return self[startIndex..<index(startIndex, offsetBy: range.count)]
    }
    subscript(range: ClosedRange<Int>) -> SubSequence {
        let startIndex = index(self.startIndex, offsetBy: range.lowerBound)
        return self[startIndex..<index(startIndex, offsetBy: range.count)]
    }
    subscript(range: PartialRangeFrom<Int>) -> SubSequence { self[index(startIndex, offsetBy: range.lowerBound)...] }
    subscript(range: PartialRangeThrough<Int>) -> SubSequence { self[...index(startIndex, offsetBy: range.upperBound)] }
    subscript(range: PartialRangeUpTo<Int>) -> SubSequence { self[..<index(startIndex, offsetBy: range.upperBound)] }
}
