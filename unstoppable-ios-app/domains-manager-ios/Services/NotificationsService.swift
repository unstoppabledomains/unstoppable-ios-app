//
//  NotificationsService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 22.07.2022.
//

import UIKit
import UserNotifications
import WalletConnectPush

// MARK: - NotificationsServiceProtocol
protocol NotificationsServiceProtocol {
    func checkNotificationsPermissions()
    func registerRemoteNotifications()
    func updateTokenSubscriptions()
    func unregisterDeviceToken()
    func didRegisterForRemoteNotificationsWith(deviceToken: Data)
}


// MARK: - NotificationsService
final class NotificationsService: NSObject {
    
    static let registerForNotificationsOptions: UNAuthorizationOptions = [.alert, .sound, .badge]
    private let notificationCenter = UNUserNotificationCenter.current()
    private let externalEventsService: ExternalEventsServiceProtocol
    private let permissionsService: PermissionsServiceProtocol
    private let udWalletsService: UDWalletsServiceProtocol

    init(externalEventsService: ExternalEventsServiceProtocol,
         permissionsService: PermissionsServiceProtocol,
         udWalletsService: UDWalletsServiceProtocol,
         wcRequestsHandlingService: WCRequestsHandlingServiceProtocol) {
        self.externalEventsService = externalEventsService
        self.permissionsService = permissionsService
        self.udWalletsService = udWalletsService
        super.init()
        notificationCenter.delegate = self
        wcRequestsHandlingService.addListener(self)
        udWalletsService.addListener(self)
        configure()
    }
    
}

// MARK: - NotificationsServiceProtocol
extension NotificationsService: NotificationsServiceProtocol {
    func checkNotificationsPermissions() {
        Task {
            let notificationsOptions: PermissionsService.Functionality = .notifications(options: NotificationsService.registerForNotificationsOptions)
            let isGranted = await permissionsService.checkPermissionsFor(functionality: notificationsOptions)
            if !isGranted {
                _ = await permissionsService.askPermissionsFor(functionality: notificationsOptions,
                                                               in: nil,
                                                               shouldShowAlertIfNotGranted: false)
            }
        }
    }
    
    func registerRemoteNotifications() {
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
    
    func didRegisterForRemoteNotificationsWith(deviceToken: Data) {
        let wallets = udWalletsService.getUserWallets()
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        let previousToken: String? = token == UserDefaults.apnsToken ? nil : UserDefaults.apnsToken
        let walletAddresses = wallets.map({ $0.address })
        let info = PushNotificationsInfo(token: token,
                                         previousToken: previousToken,
                                         walletAddresses: walletAddresses)
        Debugger.printInfo(topic: .PNs, "Device Token: \(token)")
        UserDefaults.apnsToken = token
        updatePushNotificationsInfo(info)
        registerForWC2PN(deviceToken: deviceToken)
    }
    
    func updateTokenSubscriptions() {
        guard let token = UserDefaults.apnsToken else { return }
        
        let wallets = udWalletsService.getUserWallets()
        let walletAddresses = wallets.map({ $0.address })
        let info = PushNotificationsInfo(token: token,
                                         previousToken: nil,
                                         walletAddresses: walletAddresses)
        Debugger.printInfo(topic: .PNs, "Update token subscriptions")
        updatePushNotificationsInfo(info)
    }
    
    func unregisterDeviceToken() {
        Task {
            if let token = UserDefaults.apnsToken {
                Debugger.printWarning("Will remove push token \(token)")
                let info = PushNotificationsInfo(token: token,
                                                 previousToken: nil,
                                                 walletAddresses: [])
                do {
                    try await NetworkService().updatePushNotificationsInfo(info: info)
                    UserDefaults.apnsToken = nil
                } catch {
                    Debugger.printFailure("Failed to remove push notifications info", critical: false)
                }
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationsService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // NOTE: this function will only be called when the app is in foreground.
        let presentationOptions = checkNotificationPayload(notification.request.content.userInfo, receiveState: .foreground)
        completionHandler(presentationOptions)
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let applicationState = UIApplication.shared.applicationState
        
        if response.actionIdentifier == UNNotificationDefaultActionIdentifier {
            checkNotificationPayload(response.notification.request.content.userInfo, receiveState: applicationState != .active ? .background : .foregroundAction)
        }
        completionHandler()
    }
}

// MARK: - UDWalletsServiceListener
extension NotificationsService: UDWalletsServiceListener {
    func walletsDataUpdated(notification: UDWalletsServiceNotification) {
        switch notification {
        case .walletsUpdated:
            updateTokenSubscriptions()
        case .reverseResolutionDomainChanged:
            return
        }
    }
}

// MARK: - WalletConnectServiceListener
extension NotificationsService: WalletConnectServiceConnectionListener {
    func didConnect(to app: PushSubscriberInfo?) {
        checkNotificationsPermissions()
        guard let subscriberApp = app else {
            Debugger.printFailure("Failed to get wallet info for dApp while subscribing to WC PN")
            return
        }
        
        subscribeToWC(dAppName: subscriberApp.dAppName,
                      wcWalletPeerId: subscriberApp.peerId,
                      bridgeUrl: subscriberApp.bridgeUrl,
                      domainName: subscriberApp.domainName)
    }
    
    func didDisconnect(from app: PushSubscriberInfo?) {
        guard let subscriberApp = app else {
            Debugger.printFailure("Failed to get wallet info for dApp while Unsubscribing to WC PN")
            return
        }
        unsubscribeToWC(wcWalletPeerId: subscriberApp.peerId)
    }
    
    func didCompleteConnectionAttempt() { }
}

// MARK: - Private methods
fileprivate extension NotificationsService {
    func configure() {
        configureWC2PN()
    }
    
    func configureWC2PN() {
        #if DEBUG
        Push.configure(environment: .sandbox)
        #else
        Push.configure(environment: .production)
        #endif
    }
    
    func registerForWC2PN(deviceToken: Data) {
        Task {
            do {
                try await Push.wallet.register(deviceToken: deviceToken)
                Debugger.printInfo(topic: .PNs, "Did register device token with WC2")
            } catch {
                Debugger.printInfo(topic: .PNs, "Failed to register device token with WC2 with error: \(error)")
            }
        }
    }
    
    @discardableResult
    func checkNotificationPayload(_ userInfo: [AnyHashable : Any], receiveState: ExternalEventReceivedState) -> UNNotificationPresentationOptions {
        if let json = userInfo as? [String : Any],
           let event = ExternalEvent(pushNotificationPayload: json) {
            appContext.analyticsService.log(event: event.analyticsEvent,
                                        withParameters: event.analyticsParameters)
            externalEventsService.receiveEvent(event,
                                               receivedState: receiveState)
            switch event {
            case .domainProfileUpdated, .mintingFinished, .domainTransferred, .reverseResolutionSet, .reverseResolutionRemoved, .wcDeepLink, .recordsUpdated:
                return [.list, .banner, .sound]
            case .walletConnectRequest:
                return []
            }
        }
        return []
    }
    
    func updatePushNotificationsInfo(_ info: PushNotificationsInfo) {
        Task {
            do {
                try await NetworkService().updatePushNotificationsInfo(info: info)
            } catch {
                Debugger.printFailure("Failed to update push notifications info \(error.localizedDescription)", critical: false)
                let interval: TimeInterval = 60
                let duration = UInt64(interval * 1_000_000_000)
                try? await Task.sleep(nanoseconds: duration)
                updatePushNotificationsInfo(info)
            }
        }
    }
    
    func subscribeToWC(dAppName: String, wcWalletPeerId: String, bridgeUrl: URL, domainName: String) {
        guard let token = UserDefaults.apnsToken else {
            Debugger.printFailure("Can't subscribe for WC PN because no tokens found")
            return
        }
        
        let info = WalletConnectPushNotificationsSubscribeInfo(bridgeUrl: bridgeUrl.absoluteString + "/subscribe",
                                                               wcWalletPeerId: wcWalletPeerId,
                                                               dappName: dAppName,
                                                               devicePnToken: token,
                                                               domainName: domainName)
        Task {
            do {
                try await NetworkService().subscribePushNotificationsForWCDApp(info: info)
            } catch {
                Debugger.printFailure("Failed to subscribe for WC PN with error: \(error.localizedDescription)")
            }
        }
    }
    
    func unsubscribeToWC(wcWalletPeerId: String) {
        let info = WalletConnectPushNotificationsUnsubscribeInfo(wcWalletPeerId: wcWalletPeerId)
        
        Task {
            do {
                try await NetworkService().unsubscribePushNotificationsForWCDApp(info: info)
            } catch {
                Debugger.printFailure("Failed to Unsubscribe for WC PN with error: \(error.localizedDescription)")
            }
        }
    }
}
