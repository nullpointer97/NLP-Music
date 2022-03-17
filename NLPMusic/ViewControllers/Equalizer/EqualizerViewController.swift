//
//  EqualizerViewController.swift
//  vkmusic
//
//  Created by Ярослав Стрельников on 15.02.2022.
//  Copyright © 2022 NP-Team. All rights reserved.
//

import UIKit
import CoreAudioKit

@available(iOS 13.0, *)
class EqualizerViewController: VKBaseViewController {
    @IBOutlet weak var equalizerTable: InsetGroupedTableView!
    
    let frequencies: [Int] = [32, 63, 125, 250, 500, 1000, 2000, 4000, 8000, 16000]
    let frequenciesString: [String] = ["32Hz ", "63Hz ", "125Hz", "250Hz", "500Hz", "1kHz ", "2kHz ", "4kHz ", "8kHz ", "16kHz"]
    var preSets: [[Float]] = [
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [4, 6, 5, 0, 1, 3, 5, 4.5, 3.5, 0],
        [4, 3, 2, 2.5, -1.5, -1.5, 0, 1, 2, 3],
        [5, 4, 3.5, 3, 1, 0, 0, 0, 0, 0]
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Эквалайзер (бета)"
        
        equalizerTable.delegate = self
        equalizerTable.dataSource = self
        
        equalizerTable.register(UINib(nibName: "ControlViewCell", bundle: nil), forCellReuseIdentifier: "ControlViewCell")
        
        asdk_navigationViewController?.navigationBar.prefersLargeTitles = false
    }
}

@available(iOS 13.0, *)
extension EqualizerViewController: ControlDelegate {
    func didChangeEqualizerNode(_ cell: ControlViewCell, _ sender: UISlider) {
        guard let indexPath = equalizerTable.indexPath(for: cell) else { return }
        preSets[2][indexPath.row] = sender.value
        Settings.currentBandValues = preSets[2]
    }
}

@available(iOS 13.0, *)
extension EqualizerViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        frequencies.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ControlViewCell", for: indexPath) as? ControlViewCell else { return UITableViewCell() }
        cell.controlType = .equalizer
        cell.colorPickerIntenseSwitch.value = preSets[2][indexPath.row]
        cell.colorPickerIntenseSwitch.minimumValue = -6
        cell.colorPickerIntenseSwitch.maximumValue = 6
        cell.lowerLimitLabel.text = "-6dB"
        cell.upperLimitLabel.text = "+6dB"
        cell.frequencyNameLabel.text = frequenciesString[indexPath.row]
        cell.widthConstraint.constant = 45
        cell.delegate = self
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        44
    }
}
