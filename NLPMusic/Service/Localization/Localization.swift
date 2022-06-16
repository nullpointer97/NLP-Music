//
//  Localization.swift
//  Extended Messenger
//
//  Created by Ярослав Стрельников on 16.01.2021.
//

import Foundation
import UIKit

struct Localization {
    struct ru {
        static let followersString: [String?] = ["подписчик", "подписчика", "подписчиков", nil]
        static let membersString: [String?] = ["участник", "участника", "участников", nil]
        static let pagesString: [String?] = ["интересная страница", "интересных страницы", "интересных страницы", nil]
        static let attachmentsString: [String?] = ["вложение", "вложения", "вложений", nil]
        static let docsString: [String?] = ["документ", "документа", "документов", nil]
        static let forwardString: [String?] = ["сообщение", "сообщения", "сообщений", nil]
        
        static let wallsCount: [String?] = ["запись", "записи", "записей", nil]
        static let audioCount: [String?] = ["аудио", "аудио", "аудио", nil]
        static let playlistCount: [String?] = ["плейлист", "плейлиста", "плейлистов", nil]
        static let commentsCount: [String?] = ["комментарий", "комментария", "комментариев", nil]
        static let friendsCount: [String?] = ["друг", "друга", "друзей", nil]
        static let possibleCount: [String?] = ["возможный", "возможных", "возможных", nil]
        static let searchedCount: [String?] = ["человек найден", "человека найдено", "человек найден", nil]
        static let photosCount: [String?] = ["фотография", "фотографии", "фотографий", nil]
        static let messagesCount: [String?] = ["cообщение", "cообщения", "cообщений", nil]
        static let newMessagesCount: [String?] = ["новое cообщение", "новых cообщения", "новых cообщений", nil]
        static let privateConversationsCount: [String?] = ["приватный чат", "приватных чата", "приватных чатов", nil]
        static let conversationsCount: [String?] = ["чат", "чата", "чатов", nil]
        static let ageCase: [String?] = ["год", "года", "лет", nil]
        
        static let timeSeconds: [String?] = ["секунду", "секунды", "секунд", nil]
        static let timeMinutes: [String?] = ["минуту", "минуты", "минут", nil]
        static let timeHours: [String?] = ["час", "часа", "часов", nil]

        static let plays: [String?] = ["прослушивание", "прослушивания", "прослушиваний", nil]
    }
    
    struct en {
        static let followersString: [String?] = ["follower", "followers", "followers", nil]
        static let membersString: [String?] = ["member", "members", "members", nil]
        static let pagesString: [String?] = ["interessing page", "interessing pages", "interessing pages", nil]
        static let attachmentsString: [String?] = ["attachment", "attachments", "attachments", nil]
        static let docsString: [String?] = ["document", "documents", "documents", nil]
        static let forwardString: [String?] = ["message", "messages", "messages", nil]
        
        static let wallsCount: [String?] = ["post", "posts", "posts", nil]
        static let audioCount: [String?] = ["audio", "audios", "audios", nil]
        static let playlistCount: [String?] = ["playlist", "playlists", "playlists", nil]
        static let commentsCount: [String?] = ["comment", "comments", "comments", nil]
        static let friendsCount: [String?] = ["friend", "friends", "friends", nil]
        static let possibleCount: [String?] = ["mutual", "mutuals", "mutuals", nil]
        static let searchedCount: [String?] = ["find", "finded", "finded", nil]
        static let photosCount: [String?] = ["photo", "photos", "photos", nil]
        static let messagesCount: [String?] = ["message", "messages", "messages", nil]
        static let newMessagesCount: [String?] = ["new message", "new messages", "new message", nil]
        static let privateConversationsCount: [String?] = ["private chat", "private chats", "private chats", nil]
        static let conversationsCount: [String?] = ["chat", "chats", "chats", nil]
        static let ageCase: [String?] = ["year", "years", "years", nil]
        
        static let timeSeconds: [String?] = ["second", "seconds", "second", nil]
        static let timeMinutes: [String?] = ["minute", "minutes", "minutes", nil]
        static let timeHours: [String?] = ["hour", "hours", "hours", nil]

        static let plays: [String?] = ["listen", "listening", "listening", nil]
    }
}
