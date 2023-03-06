//
//  MockNotificationsService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 02.03.2023.
//

import Foundation

final class MockNotificationsService {
    
}

extension MockNotificationsService: NotificationsServiceProtocol {
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
