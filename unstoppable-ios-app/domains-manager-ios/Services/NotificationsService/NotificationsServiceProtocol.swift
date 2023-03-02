//
//  NotificationsServiceProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 02.03.2023.
//

import Foundation

protocol NotificationsServiceProtocol {
    func checkNotificationsPermissions()
    func registerRemoteNotifications()
    func updateTokenSubscriptions()
    func unregisterDeviceToken()
    func didRegisterForRemoteNotificationsWith(deviceToken: Data)
}
