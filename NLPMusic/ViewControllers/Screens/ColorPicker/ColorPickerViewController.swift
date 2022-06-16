//
//  ColorPickerViewController.swift
//  vkmusic
//
//  Created by Ярослав Стрельников on 15.02.2022.
//  Copyright © 2022 NP-Team. All rights reserved.
//

import UIKit

class ColorPickerViewController: VKModalViewController, ControlDelegate {
    @IBOutlet weak var mainTable: NLPGroupedTableView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dismissButton: UIButton!
    
    override var panScrollable: UIScrollView? {
        return mainTable
    }
    
    override var longFormHeight: PanModalHeight {
        return .maxHeightWithTopInset(90)
    }
    
    override var shortFormHeight: PanModalHeight {
        return .maxHeightWithTopInset(90)
    }
    
    override var dragIndicatorBackgroundColor: UIColor {
        return .secondaryPopupFill
    }
    
    var footers: [String] = [
        "Поддерживается выбор цвета не отрывая пальца. После выбора цвета (когда отпустили палец), через секунду окно закроется",
        "Вы можете регулировать плотность поля выбора цвета"
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .primaryPopupFill
        
        titleLabel.text = "Цвет акцента"
        
        mainTable.delegate = self
        mainTable.dataSource = self
        
        dismissButton.setTitle("", for: .normal)
        dismissButton.backgroundColor = .secondaryPopupFill.withAlphaComponent(0.2)
        dismissButton.drawBorder(15, width: 0)
        
        mainTable.register(.listCell(.colorPicker), forCellReuseIdentifier: .listCell(.colorPicker))
        mainTable.register(.listCell(.control), forCellReuseIdentifier: .listCell(.control))
        
        asdk_navigationViewController?.navigationBar.prefersLargeTitles = false
    }

    func didChangeColorPickerIntense(_ sender: UISlider) {
        let cell = mainTable.cellForRow(at: IndexPath(row: 0, section: 0)) as? ColorPickerViewCell
        cell?.colorPicker.elementSize = CGFloat(sender.value)
    }
    
    @IBAction func dismissPopup(_ sender: UIButton) {
        dismiss(animated: true)
    }
}

extension ColorPickerViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: .listCell(.colorPicker), for: indexPath) as? ColorPickerViewCell else { return UITableViewCell() }
            cell.colorPicker.delegate = self
            return cell
        } else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: .listCell(.control), for: indexPath) as? ControlViewCell else { return UITableViewCell() }
            cell.colorPickerIntenseSwitch.value = Float(Settings.colorPickerElementSize)
            cell.widthConstraint.constant = 0
            cell.delegate = self
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        footers[section]
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard section == 0 else { return nil }
        return " "
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        footers[section].height(withConstrainedWidth: tableView.bounds.width - 64, font: .systemFont(ofSize: 13)) + 12
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        indexPath.section == 0 ? tableView.bounds.width : 44
    }
}

extension ColorPickerViewController: HSBColorPickerDelegate {
    func HSBColorColorPickerTouched(sender: HSBColorPicker, color: UIColor, point: CGPoint, state: UIGestureRecognizer.State) {
        Settings.setValue(forKey: "_accentColor", value: color.hex)
        let cell = mainTable.cellForRow(at: IndexPath(row: 0, section: 1)) as? ControlViewCell
        cell?.colorPickerIntenseSwitch.minimumTrackTintColor = .getAccentColor(fromType: .common)

        let tabBarController = (presentingViewController as? VKTabController)
        let asdk_navigationViewController = tabBarController?.viewControllers?.last as? VKMNavigationController
        UIView.transition(.promise, with: view, duration: 0.2) {
            let settingsController = asdk_navigationViewController?.topViewController as? ASSettingsViewController
            settingsController?.tableNode.performBatchUpdates {
                settingsController?.tableNode.reloadData()
            }

            asdk_navigationViewController?.navigationBar.tintColor = .getAccentColor(fromType: .common)
            tabBarController?.popupBar.progressView.progressTintColor = .getAccentColor(fromType: .common)
            tabBarController?.view.layoutIfNeeded()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.dismiss(animated: true)
        }
    }
    
    func HSBColorColorPickerPanoramed(sender: HSBColorPicker, color: UIColor, point: CGPoint, state: UIGestureRecognizer.State) {
        let cell = mainTable.cellForRow(at: IndexPath(row: 0, section: 1)) as? ControlViewCell
        cell?.colorPickerIntenseSwitch.minimumTrackTintColor = color
    }
}
