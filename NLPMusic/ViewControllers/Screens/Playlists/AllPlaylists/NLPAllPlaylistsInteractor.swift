//
//  NLPAllPlaylistsInteractor.swift
//  NLPMusic
//
//  Created by Ярослав Стрельников on 02.04.2022.
//  Copyright (c) 2022 Extended Team. All rights reserved.
//

import Foundation
import Alamofire
import ObjectMapper

final class NLPAllPlaylistsInteractor {
    weak var presenter: NLPAllPlaylistsPresenterInterface?
}

// MARK: - Extensions -

extension NLPAllPlaylistsInteractor: NLPAllPlaylistsInteractorInterface {
    func getPlaylists(isPaginate: Bool = false) throws {
        var parametersAudio: Parameters = [
            "owner_id" : currentUserId,
            "count" : 200,
        ]
        
        if isPaginate {
            parametersAudio["start_from"] = presenter?.nextFrom
        }
        
        try ApiV2.method(.getPlaylists, parameters: &parametersAudio, apiVersion: .defaultApiVersion).done { result in
            self.presenter?.nextFrom = result["response"]["next_from"].string ?? ""
            self.presenter?.isPageNeed = self.presenter?.nextFrom.isEmpty ?? false
            guard let data = try? result.rawData() else { return }
            guard let items = Mapper<Response<PlaylistResponse>>().map(JSONString: data.string(encoding: .utf8) ?? "{ }")?.response.items else { return }
            
            if isPaginate {
                self.presenter?.playlistItems.append(contentsOf: items.uniqued())
            } else {
                self.presenter?.playlistItems.removeAll()
                self.presenter?.playlistItems.insert(contentsOf: items.uniqued(), at: 0)
            }
            
            for duplicate in self.presenter?.playlistItems.duplicates() ?? [] {
                self.presenter?.playlistItems.remove(duplicate)
            }
        }.ensure {
            self.presenter?.onDidFinishLoad()
        }.catch { error in
            self.presenter?.onError(message: "\(String.localized(.loadingError))\n\(error.toVK().toApi()?.message ?? "")")
        }
    }
    
    func deletePlaylist(playlist: Playlist) throws {
        var parameters: Parameters = [
            "playlist_id": playlist.id ?? 0,
            "owner_id" : currentUserId
        ]
        
        try ApiV2.method(.deletePlaylist, parameters: &parameters, apiVersion: .defaultApiVersion).done { result in
            guard result["response"].intValue == 1 else { return }
            self.presenter?.didRemovePlaylist(playlist: playlist)
        }.ensure {
            self.presenter?.onDidFinishLoad()
        }.catch { error in
            self.presenter?.onError(message: "\(String.localized(.deleteError))\n\(error.toVK().toApi()?.message ?? "")")
        }
    }
}
