//
//  PreviewNotificationsService.swift
//  unstoppable-preview
//
//  Created by Oleg Kuplin on 01.12.2023.
//

import Foundation
import UserNotifications

final class NotificationsService: NotificationsServiceProtocol {
    static let registerForNotificationsOptions: UNAuthorizationOptions = [.alert, .sound, .badge]

    func checkNotificationsPermissions() {
        
    }
    
    func registerRemoteNotifications() {
        
    }
    
    func updateTokenSubscriptions() {
        
    }
    
    func unregisterDeviceToken() {
        
    }
    
    func didRegisterForRemoteNotificationsWith(deviceToken: Data) {
        
    }
}
