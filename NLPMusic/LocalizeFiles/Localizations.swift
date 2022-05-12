//
//  Localizations.swift
//  NLPMusic
//
//  Created by Ярослав Стрельников on 12.05.2022.
//  Copyright © 2022 NP-Team. All rights reserved.
//

import Foundation

enum Localizations: String {
    // MARK: Search
    case searchPlaceholder = "NLPSearchAudioViewController.Search.SearchPlaceholder"
    case footerKeyword = "NLPSearchAudioViewController.Search.FooterKeyword"
    case endList = "NLPSearchAudioViewController.Search.EndList"
    case nothingFound = "NLPSearchAudioViewController.Search.NothingFound"
    
    // MARK: Titles
    case musicTitle = "NLPTabController.Music.Title"
    case audiosTitle = "NLPTabController.Audios.Title"
    case recommendationsTitle = "NLPTabController.Recommendations.Title"
    case searchTitle = "NLPTabController.Search.Title"
    case freindsTitle = "NLPTabController.Freinds.Title"
    case friendsMusicTitle = "NLPMNavigationController.Freinds.Title"
    case settingsTitle = "NLPTabController.Settings.Title"
    case savedMusicTitle = "NLPTabController.SavedMusic.Title"
    case playerWaitPrefix = "NLPTabController.Player.Prefix"
    case playerWaitSuffix = "NLPTabController.Player.Suffix"

    // MARK: Actions
    case save = "NLPBaseTableViewController.Actions.Save"
    case addToLibrary = "NLPBaseTableViewController.Actions.AddToLibrary"
    case delete = "NLPBaseTableViewController.Actions.Delete"
    case deleteFromCache = "NLPBaseTableViewController.Actions.DeleteFromCache"
    case interactiveSwipe = "NLPBaseTableViewController.Actions.InteractiveSwipe"
    case resistingSwipe = "NLPBaseTableViewController.Actions.ResistingSwipe"
    case cancel = "NLPBaseTableViewController.Actions.Cancel"
    case logout = "NLPBaseTableViewController.Actions.Logout"
    case reload = "NLPBaseViewController.Actions.Reload"
    case shuffle = "NLPBaseViewController.Actions.Shuffle"

    // MARK: Errors
    case deleteError = "NLPBaseViewController.Errors.DeleteError"
    case incorrectLoginData = "NLPBaseViewController.Errors.IncorrectLoginData"
    case audioURLError = "NLPBaseViewController.Errors.AudioURLError"
    case loadingError = "NLPBaseViewController.Errors.LoadingError"
    case addError = "NLPBaseViewController.Errors.AddError"
    case commonError = "NLPBaseViewController.Errors.CommonError"
    case noAudios = "NLPBaseViewController.Errors.NoAudios"
    case noAudiosPrefix = "NLPBaseViewController.Errors.UserNoAudiosPrefix"
    case noAudiosSuffix = "NLPBaseViewController.Errors.UserNoAudiosSuffix"
    case noPlaylists = "NLPBaseViewController.Errors.NoPlaylist"
    
    // MARK: Alerts
    case logoutTitle = "NLPBaseViewController.Alerts.Logout"
    case clearCacheTitle = "NLPBaseViewController.Alerts.ClearCacheTitle"
    case clearCache = "NLPBaseViewController.Alerts.ClearCache"
    case temporarilyUnavailable = "NLPBaseViewController.Alerts.TemporarilyUnavailable"
    case alreadyDownloaded = "NLPBaseViewController.Alerts.AlreadyDownloaded"
    case fileLoading = "NLPBaseViewController.Alerts.FileLoading"
    case errorDownload = "NLPBaseViewController.Alerts.ErrorDownload"
    case needReload = "NLPBaseViewController.Alerts.NeedReload"
    case added = "NLPBaseViewController.Alerts.Added"
    
    // MARK: Settings
    case playerStyle =  "NLPSettingsController.Settings.PlayerStyle"
    case accentColor = "NLPSettingsController.Settings.AccentColor"
    case playerSwipe = "NLPSettingsController.Settings.PlayerSwipe"
    case language = "NLPSettingsController.Settings.Language"
    case tabbarNames = "NLPSettingsController.Settings.TabbarNames"
    case autoDownload = "NLPSettingsController.Settings.AutoDownload"
    case downloadWifi = "NLPSettingsController.Settings.DownloadWifi"
    case clearCacheSettings = "NLPSettingsController.Settings.ClearCache"
    case updates = "NLPSettingsController.Settings.Updates"
    case tgChannel = "NLPSettingsController.Settings.TelegramChannel"
    case donate = "NLPSettingsController.Settings.Donate"
    case report = "NLPSettingsController.Settings.Report"
    case logoutSettings = "NLPSettingsController.Settings.Logout"
    
    // MARK: Footers
    case updatesFooter = "NLPSettingsController.Footer.Updates"
    case cacheFooter = "NLPSettingsController.Footer.CacheSize"

    // MARK: Common
    case commonErrorTitle = "NLPCommon.Error"
    case commonSuccessTitle = "NLPCommon.Success"
    case commonWarningTitle = "NLPCommon.Warning"
    case donateDescription = "NLPCommon.Donate"
    case trouble = "NLPCommon.Trouble"
}

extension String {
    static func localized(_ localizedString: Localizations, comment: String = "no comment") -> String {
        return NSLocalizedString(localizedString.rawValue, comment: comment)
    }
}
