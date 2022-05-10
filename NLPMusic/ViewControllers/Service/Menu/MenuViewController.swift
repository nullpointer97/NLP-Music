//
//  MenuViewController.swift
//  vkmusic
//
//  Created by Ярослав Стрельников on 03.02.2022.
//  Copyright © 2022 NP-Team. All rights reserved.
//

import Foundation
import UIKit

struct AudioItemAction {
    var actionDescription: String
    var title: String
    var action: ((Any?) -> (Void))?
}

class MenuViewController: UITableViewController {
    var actions: [[AudioItemAction]] = [[AudioItemAction(actionDescription: "save", title: "Сохранить", action: nil)], [AudioItemAction(actionDescription: "remove", title: "Удалить", action: nil)]]
    var item: AudioPlayerItem?
    weak var actionDelegate: AudioItemActionDelegate?
    
    init(from item: AudioPlayerItem) {
        self.item = item
        super.init(style: .plain)
    }
    
    init() {
        super.init(style: .plain)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.reloadData()
        tableView.layoutIfNeeded()
        tableView.separatorInset.left = -17
        tableView.isScrollEnabled = false
        preferredContentSize = CGSize(width: 200, height: tableView.contentSize.height - 2)
        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
        tableView.backgroundColor = .contextColor
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return actions[section].count
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return actions.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = actions[indexPath.section][indexPath.row].title
        cell.textLabel?.font = .systemFont(ofSize: 17)
        cell.backgroundColor = .clear
        cell.accessoryType = .disclosureIndicator
        
        if actions[indexPath.section][indexPath.row].actionDescription == "remove" {
            cell.textLabel?.textColor = .systemRed
        }
        
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if let action = actions[indexPath.section][indexPath.row].action {
            action(nil)
        }
    }
}
