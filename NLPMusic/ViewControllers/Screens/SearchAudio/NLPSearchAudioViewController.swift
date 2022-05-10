//
//  NLPSearchAudioViewController.swift
//  vkmusic
//
//  Created by Ярослав Стрельников on 01.03.2022.
//  Copyright © 2022 NP-Team. All rights reserved.
//

import UIKit
import CoreStore
import Alamofire
import ShazamKit
import MaterialComponents
import ShazamKit

class NLPSearchAudioViewController: NLPBaseTableViewController {
    @available(iOS 15.0, *)
    private lazy var shazamSession: SHSession = {
        return SHSession()
    }()
    private let audioEngine = AVAudioEngine()
    private let feedback = UINotificationFeedbackGenerator()
    
    var presenter: NLPSearchAudioPresenterInterface!

    var searchController: UISearchController!
    var searchKeyword: String = ""
    var isShazamed: Bool = false
    var workItem: DispatchWorkItem?
    var pulseButton = NLPPulseButton()

    init() {
        super.init(nibName: nil, bundle: nil)
        
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.delegate = self
        searchController.searchBar.placeholder = "Поиск музыки"
        searchController.searchBar.delegate = self
        searchController.searchBar.setImage(UIImage(named: "search_outline_28")?.resize(toWidth: 18)?.resize(toHeight: 18)?.tint(with: .systemGray), for: .search, state: .normal)
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.searchBarStyle = .minimal
        navigationItem.searchController = searchController
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTable()
        
        pulseButton.title = ""
        pulseButton.autoSetDimensions(to: .identity(28))
        pulseButton.buttonBackgroundColor = .getAccentColor(fromType: .common).withAlphaComponent(0.75)
        pulseButton.pulseBackgroundColor = .getAccentColor(fromType: .common).withAlphaComponent(0.35)
        pulseButton.circle = true
        
        if #available(iOS 15.0, *) {
            shazamSession.delegate = self
            pulseButton.addTarget(self, action: #selector(didBeginRecognizing), for: .touchUpInside)
            navigationItem.rightBarButtonItem = UIBarButtonItem(customView: pulseButton)
            
            observables.append(UserDefaults.standard.observe(UInt32.self, key: "_accentColor") {
                _ = $0
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: self.pulseButton)
            })
        }
        
        navigationItem.hidesSearchBarWhenScrolling = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        searchController.searchBar.setImage(UIImage(named: "search")?.resize(toWidth: 18)?.resize(toHeight: 18)?.tint(with: .systemGray), for: .search, state: .normal)
    }
    
    override func setupTable(style: UITableView.Style = .plain) {
        super.setupTable()
        tableView.refreshControl = nil
        tableView.keyboardDismissMode = .onDrag
        
        definesPresentationContext = true

        tableView.isSkeletonable = true
    }
    
    override func didOpenMenu(audio cell: NLPBaseViewCell<AudioPlayerItem>) {
        super.didOpenMenu(audio: cell)
        
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let item = audioItems[indexPath.row]
        
        let saveAction = MDCActionSheetAction(title: "Сохранить", image: UIImage(named: "download_outline_28")?.tint(with: .label)) { [weak self] _ in
            guard let self = self else { return }
            self.didSaveAudio(item, indexPath: indexPath)
        }
        saveAction.tintColor = .label
        saveAction.titleColor = .label
        
        let addAction = MDCActionSheetAction(title: "Добавить к себе", image: UIImage(named: "add_outline_24")?.tint(with: .label)) { [weak self] _ in
            guard let self = self else { return }
            do {
                try self.presenter.onAddAudio(audio: item)
            } catch {
                self.showEventMessage(.error, message: error.localizedDescription)
            }
        }
        addAction.tintColor = .label
        addAction.titleColor = .label
        
        let removeInCacheAction = MDCActionSheetAction(title: "Удалить из кэша", image: UIImage(named: "delete_outline_28")?.tint(with: .systemRed)) { [weak self] _ in
            guard let self = self else { return }
            self.didRemoveAudio(item, indexPath: indexPath)
        }
        removeInCacheAction.tintColor = .systemRed
        removeInCacheAction.titleColor = .systemRed
        openMenu(fromItem: item, actions: item.isDownloaded ? [addAction, removeInCacheAction] : [addAction, saveAction])
    }
    
    override func reload() {
        super.reload()
        
        dataSource?.footerLineText = audioItems.isEmpty ? "Введите ключевое слово для поиска" : "Конец списка"
    }
    
    override func didFinishLoad() {
        super.didFinishLoad()
        
        tableView.hideSkeleton()
    }
    
    override func tableView(_ tableView: UITableView, willNeedPaginate cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == audioItems.count && presenter.isPageNeed {
            do {
                try presenter.onSearchAudio(byKeyword: searchKeyword, isPaginate: true)
            } catch {
                print(error)
            }
        }
    }
    
    @available(iOS 15.0, *)
    private func prepareAudioRecording() throws {
        let audioSession = AVAudioSession.sharedInstance()
        
        try audioSession.setCategory(.record)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    }
    
    @available(iOS 15.0, *)
    private func generateSignature() {
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: .zero)
        
        inputNode.installTap(onBus: .zero, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.shazamSession.matchStreamingBuffer(buffer, at: nil)
        }
    }
    
    @available(iOS 15.0, *)
    private func startAudioRecording() throws {
        try audioEngine.start()
        
        isShazamed = true
    }
    
    @available(iOS 15.0, *)
    private func stopRecognition() {
        _ = try? AVAudioSession.sharedInstance().setCategory(.playback)
        _ = try? AVAudioSession.sharedInstance().setActive(true)
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: .zero)
        
        UIView.animate(withDuration: 0.3, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction]) { [weak self] in
            guard let self = self else { return }
            self.pulseButton.buttonBackgroundColor = .getAccentColor(fromType: .common).withAlphaComponent(0.75)
            self.pulseButton.pulseBackgroundColor = .getAccentColor(fromType: .common).withAlphaComponent(0.35)
            self.pulseButton.superview?.layoutIfNeeded()
        }
        
        pulseButton.animate(start: false)
    }
    
    @available(iOS 15.0, *)
    private func startRecognition() {
        feedback.prepare()
        
        // 1
        do {
            if audioEngine.isRunning {
                stopRecognition()
                return
            }
            
            // 2
            try prepareAudioRecording()
            
            generateSignature()
            
            try startAudioRecording()
            
            feedback.notificationOccurred(.success)
        } catch {
            // Handle errors here
            print(error)
            feedback.notificationOccurred(.error)
        }
    }
    
    @available(iOS 15.0, *)
    @objc func didBeginRecognizing() {
        isShazamed.toggle()
        
        UIView.animate(withDuration: 0.3, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction]) { [weak self] in
            guard let self = self else { return }
            self.pulseButton.buttonBackgroundColor = self.isShazamed ? .systemRed.withAlphaComponent(0.75) : .getAccentColor(fromType: .common).withAlphaComponent(0.75)
            self.pulseButton.pulseBackgroundColor = self.isShazamed ? .systemRed.withAlphaComponent(0.35) : .getAccentColor(fromType: .common).withAlphaComponent(0.35)
            self.pulseButton.superview?.layoutIfNeeded()
        }
        
        pulseButton.animate(start: isShazamed)
        
        if isShazamed {
            startRecognition()
        } else {
            stopRecognition()
        }
    }
    
    @objc func didClearCache() {
        reload()
    }
}

extension NLPSearchAudioViewController: NLPSearchAudioViewInterface {
}

extension NLPSearchAudioViewController: UISearchControllerDelegate {
    func willDismissSearchController(_ searchController: UISearchController) {
        searchController.searchBar.placeholder = searchKeyword.isEmpty ? "Поиск музыки" : searchKeyword
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchKeyword = ""
        audioItems.removeAll()
        reload()
    }
}

extension NLPSearchAudioViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchKeyword = searchText
        audioItems.removeAll()
        reload()

        self.workItem?.cancel()
        
        guard searchText.count >= 1 else {
            return
        }

        let workItem = DispatchWorkItem { [weak self] in
            self?.performSearch()
        }
        
        // Run this block after 0.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: workItem)
        
        // Keep a reference to it so it can be cancelled
        self.workItem = workItem
    }
    
    @objc func performSearch() {
        tableView.showAnimatedGradientSkeleton()
        do {
            try presenter.onSearchAudio(byKeyword: searchKeyword, isPaginate: true)
        } catch {
            print(error)
        }
        isShazamed = false
    }
}

extension NLPSearchAudioViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text, searchText.count >= 1 && isShazamed else { return }
        self.workItem?.cancel()
        
        guard searchText.count >= 1 else {
            return
        }

        let workItem = DispatchWorkItem { [weak self] in
            self?.performSearch()
        }
        
        // Run this block after 0.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: workItem)
        
        // Keep a reference to it so it can be cancelled
        self.workItem = workItem
    }
}

@available(iOS 15.0, *)
extension NLPSearchAudioViewController: SHSessionDelegate {
    func session(_ session: SHSession, didFind match: SHMatch) {
        guard let mediaItem = match.mediaItems.first else { return }
        guard let title = mediaItem.title else { return }
        DispatchQueue.main.async {
            self.searchKeyword = "\(title) - \(mediaItem.artist ?? "")"
            
            self.isShazamed = true
            self.searchController?.searchBar.text = self.searchKeyword
            self.stopRecognition()
        }
    }
}
