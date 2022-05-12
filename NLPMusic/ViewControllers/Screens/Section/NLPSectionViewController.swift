//
//  NLPSectionViewController.swift
//  NLPMusic
//
//  Created by Ярослав Стрельников on 12.05.2022.
//  Copyright © 2022 NP-Team. All rights reserved.
//

import Foundation
import UIKit
import Alamofire

final class NLPSectionViewController: NLPBaseTableViewController {
    var sectionId: String
    
    init(sectionId: String) {
        self.sectionId = sectionId
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        sectionId = ""
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTable()
        getSection()
    }
    
    override func setupTable(style: UITableView.Style = .plain) {
        super.setupTable(style: style)
    }
    
    func getSection() {
        var parameters: Parameters = ["section_id": sectionId]
        do {
            try ApiV2.method("catalog.getSection", parameters: &parameters, apiVersion: "5.171").done { result in
                let audioBlock = result["response"]["section"]["blocks"].arrayValue[1]
                try self.getAudiosByIds(audios: audioBlock["audios_ids"].arrayValue.compactMap { $0.stringValue })
            }.catch { err in
                print(err)
            }
        } catch {
            print(error)
        }
    }
    
    private func getAudiosByIds(audios: [String]) throws {
        var parameters: Parameters = ["audios": audios]
        try ApiV2.method("audio.getById", parameters: &parameters, requestMethod: .get, apiVersion: "5.171").done { response in
            let audios = response["response"].arrayValue
            self.audioItems.insert(contentsOf: audios.compactMap { AudioPlayerItem(fromJSON: $0) }.uniqued(), at: self.audioItems.count)
        }.ensure {
            self.didFinishLoad()
        }.catch { err in
            self.error(message: "Произошла ошибка при загрузке\n\(err.toVK().toApi()?.message ?? "")")
        }
    }
}
