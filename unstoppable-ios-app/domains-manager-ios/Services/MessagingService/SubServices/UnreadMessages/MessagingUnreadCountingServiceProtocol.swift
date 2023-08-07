//
//  MessagingUnreadCountingServiceProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.08.2023.
//

import Foundation

protocol MessagingUnreadCountingServiceProtocol: AnyObject {
    var totalUnreadMessagesCountUpdated: ((Bool)->())? { get set }
    
    func getTotalNumberOfUnreadMessages() -> Int
    func getNumberOfUnreadMessagesIn(chatId: String, userId: String) -> Int
}
