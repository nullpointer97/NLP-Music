//
//  NLPSettingsController.swift
//  NLPMusic
//
//  Created by Ярослав Стрельников on 25.04.2022.
//  Copyright © 2022 NP-Team. All rights reserved.
//

import Foundation
import UIKit
import Alamofire
import SwiftyJSON
import MaterialComponents
import SafariServices

enum NLPSettingsSection {
    case user
    case ui
    case manage
    case updates
    case another
}

class NLPSettingsController: NLPBaseTableViewController {
    var settingsHeader = NLPSettingsHeaderView(frame: .init(x: 0, y: 0, width: screenWidth, height: NLPSettingsHeaderView.getHeight()))
    var settings: [[SettingViewModel]] = Settings.build()
    var footers: [String?] = {
        let bundle = Bundle.main
        let versionNumber = bundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let buildNumber = bundle.infoDictionary?[kCFBundleVersionKey as String] as? String ?? "1.0"
        return [nil, nil, "\(String.localized(.cacheFooter)) \(Settings.cacheSize)", String.localized(.updatesFooter), "NLP Music \(versionNumber)-\(buildNumber)"]
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = .localized(.settingsTitle)
        asdk_navigationViewController?.navigationBar.alpha = 0
        
        setupTable()
        getUser()
        
        NotificationCenter.default.addObserver(self, selector: #selector(didCleanCache), name: NSNotification.Name("didCleanCache"), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func setupTable(style: UITableView.Style = .plain) {
        super.setupTable(style: .insetGrouped)
        
        tableView.register(.listCell(.setting), forCellReuseIdentifier: .listCell(.setting))
        tableView.register(.listCell(.bigUser), forCellReuseIdentifier: .listCell(.bigUser))
        tableView.delegate = self
        tableView.dataSource = self
        tableView.refreshControl = nil
    }
    
    func getUser() {
        var parameters: Parameters = ["fields": Constants.userFields]
        
        do {
            try ApiV2.method(.getUsers, parameters: &parameters).done { [weak self] users in
                guard let self = self else { return }
                
                let user = NLPUser(users["response"].arrayValue.first ?? JSON())
                self.settings[0][0].user = user
                
                DispatchQueue.main.async {
                    self.tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .fade)
                }
            }.ensure {
                DispatchQueue.main.async {
                    self.didFinishLoad()
                }
            }.catch { error in
                self.showEventMessage(.error, message: error.localizedDescription)
            }
        } catch {
            showEventMessage(.error, message: error.localizedDescription)
        }
    }
    
    @objc func didCleanCache() {
        footers[2] = "\(String.localized(.cacheFooter)) \(Settings.cacheSize)"
        settings[2][2].isEnabled = Settings.cacheSizeInt > 0
        tableView.reloadSections(IndexSet(integer: 2), with: .fade)
        tableView.reloadRows(at: [IndexPath(row: 2, section: 2)], with: .fade)
    }
}

extension NLPSettingsController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return settings.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settings[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let setting = settings[indexPath.section][indexPath.row]
        if indexPath.section == 0 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: .listCell(.bigUser), for: indexPath) as? NLPSettingUserViewCell else { return UITableViewCell() }
            if let user = setting.user {
                cell.configure(with: user)
            }
            return cell
        } else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: .listCell(.setting), for: indexPath) as? NLPSettingViewCell else { return UITableViewCell() }
            cell.configure(with: setting)
            cell.settingDelegate = self
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return footers[section]
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return settings[indexPath.section][indexPath.row].isEnabled && indexPath.section > 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return indexPath.section == 0 ? 78 : 44
    }
}

extension NLPSettingsController: SettingActionDelegate {
    func didChangeSetting(_ cell: NLPSettingViewCell, forKey key: String, value: Bool) {
        switch cell.type {
        case .plain, .action(_), .additionalText, .anotherView:
            break
        case .switch:
            switch key {
            case "_progressDown":
                UIView.transition(.promise, with: view, duration: 0.2) {
                    self.tabBarController?.popupBar.progressViewStyle = !value ? .top : .bottom
                    self.tabBarController?.popupBar.layoutIfNeeded()
                }
            case "_namesInTabbar":
                UIView.transition(.promise, with: view, duration: 0.2) {
                    self.tabBarController?.tabBar.layoutIfNeeded()
                }
            default: break
            }
            Settings.setValue(forKey: key, value: value)
        }
    }
    
    func didTap(_ cell: NLPSettingViewCell) {
        switch cell.type {
        case .switch, .plain:
            break
        case .additionalText(let action):
            switch action {
            case .changeDismissType(_):
                let snapAction = MDCActionSheetAction(title: .localized(.resistingSwipe), image: .init(named: "snap_24")) { [weak self] _ in
                    guard let self = self else { return }
                    self.changeDismissType(0)
                }
                snapAction.tintColor = .label
                snapAction.titleColor = .label
                snapAction.isEnabled = true
                
                let interactiveAction = MDCActionSheetAction(title: .localized(.interactiveSwipe), image: .init(named: "interactive_24")) { [weak self] _ in
                    guard let self = self else { return }
                    self.changeDismissType(1)
                }
                interactiveAction.tintColor = .label
                interactiveAction.titleColor = .label
                interactiveAction.isEnabled = true
                
                openMenu(actions: [snapAction, interactiveAction], title: cell.settingTitleLabel.text)
            case .changePlayerStyle(_):
                let vkAction = MDCActionSheetAction(title: PlayerStyle.vk.rawValue, image: .init(named: "logo_vk_24")) { [weak self] _ in
                    guard let self = self else { return }
                    self.changePlayerStyle(.vk)
                }
                vkAction.tintColor = .label
                vkAction.titleColor = .label
                vkAction.isEnabled = true
                
                let appleAction = MDCActionSheetAction(title: PlayerStyle.appleMusic.rawValue, image: .init(named: "logo_apple_24")) { [weak self] _ in
                    guard let self = self else { return }
                    self.changePlayerStyle(.appleMusic)
                }
                appleAction.tintColor = .label
                appleAction.titleColor = .label
                appleAction.isEnabled = true
                
                let nlpAction = MDCActionSheetAction(title: PlayerStyle.nlp.rawValue, image: .init(named: "logo_nlp_24")) { [weak self] _ in
                    guard let self = self else { return }
                    self.changePlayerStyle(.nlp)
                }
                nlpAction.tintColor = .label
                nlpAction.titleColor = .label
                
                openMenu(actions: [vkAction, appleAction, nlpAction], title: cell.settingTitleLabel.text)
            case .changeLanguage(_):
                let ruAction = MDCActionSheetAction(title: Language.russian.name, image: nil) { [weak self] _ in
                    guard let self = self else { return }
                    DispatchQueue.main.async {
                        let alert = UIAlertController(title: .localized(.needReload), message: nil, preferredStyle: .alert)
                        
                        let confrim = UIAlertAction(title: .localized(.reload), style: .destructive) { _ in
                            self.changeLaunguge(.russian)
                        }
                        
                        let cancel = UIAlertAction(title: .localized(.cancel), style: .cancel) { _ in
                            alert.dismiss(animated: true)
                        }
                        
                        alert.addAction(confrim)
                        alert.addAction(cancel)
                        
                        self.present(alert, animated: true)
                    }
                }
                ruAction.tintColor = .label
                ruAction.titleColor = .label
                ruAction.isEnabled = true
                
                let enAction = MDCActionSheetAction(title: Language.english(.us).name, image: nil) { [weak self] _ in
                    guard let self = self else { return }
                    DispatchQueue.main.async {
                        let alert = UIAlertController(title: .localized(.needReload), message: nil, preferredStyle: .alert)
                        
                        let confrim = UIAlertAction(title: .localized(.reload), style: .destructive) { _ in
                            self.changeLaunguge(.english(.us))
                        }
                        
                        let cancel = UIAlertAction(title: .localized(.cancel), style: .cancel) { _ in
                            alert.dismiss(animated: true)
                        }
                        
                        alert.addAction(confrim)
                        alert.addAction(cancel)
                        
                        self.present(alert, animated: true)
                    }
                }
                enAction.tintColor = .label
                enAction.titleColor = .label
                enAction.isEnabled = true
                
                openMenu(actions: [ruAction, enAction], title: cell.settingTitleLabel.text)
            default: break
            }
        case .anotherView:
            DispatchQueue.main.async { [self] in
                let colorPickerViewController = NLPColorPickerViewController()
                colorPickerViewController.delegate = self
                colorPickerViewController.selectedColor = .color(from: Settings.accentColor)
                present(colorPickerViewController, animated: true)
            }
        case .action(let action):
            switch action {
            case .tgChannel(_):
                guard let url = URL(string: "https://t.me/+d_Vk18opzow0MTky") else { return }
                let config = SFSafariViewController.Configuration()
                
                config.barCollapsingEnabled = true
                config.entersReaderIfAvailable = true
                
                let safariViewController = SFSafariViewController(url: url, configuration: config)
                present(safariViewController, animated: true)
            case .donate(_):
                let donateScreen = DonateViewController()
                present(donateScreen, animated: true)
            case .report(_):
                DispatchQueue.main.async { [self] in
                    let controller = TroubleSenderViewController()
                    present(controller, animated: true)
                }
            case .changeAccentColor(_):
                break
            case .logout(let void):
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: .localized(.logoutSettings), message: .localized(.logoutTitle), preferredStyle: .alert)
                    
                    let confrim = UIAlertAction(title: .localized(.logout), style: .destructive) { _ in
                        void()
                    }
                    
                    let cancel = UIAlertAction(title: .localized(.cancel), style: .cancel) { _ in
                        alert.dismiss(animated: true)
                    }
                    
                    alert.addAction(confrim)
                    alert.addAction(cancel)
                    
                    self.present(alert, animated: true)
                }
            case .cleanCache(let void):
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: .localized(.clearCacheTitle), message: .localized(.clearCache), preferredStyle: .alert)
                    
                    let confrim = UIAlertAction(title: .localized(.delete), style: .destructive) { _ in
                        void()
                    }
                    
                    let cancel = UIAlertAction(title: .localized(.cancel), style: .cancel) { _ in
                        alert.dismiss(animated: true)
                    }
                    
                    alert.addAction(confrim)
                    alert.addAction(cancel)
                    
                    self.present(alert, animated: true)
                }
            default: break
            }
        }
    }
    
    private func changeLaunguge(_ lang: Language) {
        Bundle.set(language: lang)
        Settings.language = lang.name
        settings[1][4].subtitle = lang.name

        UIControl().sendAction(#selector(NSXPCConnection.suspend), to: UIApplication.shared, for: nil)
        exit(0)
    }

    private func changePlayerStyle(_ style: PlayerStyle) {
        switch style {
        case .vk:
            Settings.playerStyle = 1
            Settings.progressDown = true
        case .appleMusic:
            Settings.playerStyle = 0
            Settings.progressDown = false
        case .nlp:
            Settings.playerStyle = 2
            Settings.progressDown = false
        }
        settings[1][0].subtitle = style.rawValue
        
        tableView.reloadRows(at: [IndexPath(row: 0, section: 1)], with: .fade)
    }
    
    private func changeDismissType(_ type: Int) {
        Settings.dismissType = type
        settings[1][2].subtitle = type == 0 ? "Snap" : "Interactive"
        
        tableView.reloadRows(at: [IndexPath(row: 2, section: 1)], with: .fade)
    }
}

extension NLPSettingsController: ColorPickerDelegate {
    func colorPicker(_ controller: NLPColorPickerViewController?, selectedColor: UIColor, usingControl: ColorControl) {
        controller?.colorSelectButton.backgroundColor = selectedColor
        
        let saturation: CGFloat = selectedColor.getSaturation()
        controller?.colorSelectButton.titleLabel?.textColor = saturation < 0.3 ? .black : .white
    }

    func colorPicker(_ controller: NLPColorPickerViewController?, confirmedColor: UIColor, usingControl: ColorControl) {
        Settings.setValue(forKey: "_accentColor", value: confirmedColor.hex)
        // controller?.dismiss(animated: true)

        UIView.transition(.promise, with: view, duration: 0.2) {
            UISwitch.appearance().onTintColor = .getAccentColor(fromType: .common)
            UINavigationBar.appearance().tintColor = .getAccentColor(fromType: .common)
            
            self.tableView.reloadRows(at: [IndexPath(row: 1, section: 1), IndexPath(row: 3, section: 1), IndexPath(row: 0, section: 2)], with: .fade)
            
            self.tabBarController?.popupBar.progressView.progressTintColor = .getAccentColor(fromType: .common)
            self.tabBarController?.view.layoutIfNeeded()
        }
    }
}
