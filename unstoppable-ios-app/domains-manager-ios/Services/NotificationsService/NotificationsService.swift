//
//  NotificationsService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 22.07.2022.
//

import UIKit
import UserNotifications
import WalletConnectPush
import WalletConnectEcho

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
        Task { @MainActor in
            Debugger.printInfo(topic: .PNs, "Did receive PN in foreground: \(notification.request.content.userInfo)")
            let presentationOptions = checkNotificationPayload(notification.request.content.userInfo, receiveState: .foreground)
            completionHandler(presentationOptions)
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        Task { @MainActor in
            let applicationState = UIApplication.shared.applicationState
            Debugger.printInfo(topic: .PNs, "Did receive PN in background: \(response.notification.request.content.userInfo)")
            
            if response.actionIdentifier == UNNotificationDefaultActionIdentifier {
                checkNotificationPayload(response.notification.request.content.userInfo, receiveState: applicationState != .active ? .background : .foregroundAction)
            }
            completionHandler()
        }
    }
}

// MARK: - UDWalletsServiceListener
extension NotificationsService: UDWalletsServiceListener {
    func walletsDataUpdated(notification: UDWalletsServiceNotification) {
        switch notification {
        case .walletsUpdated:
            updateTokenSubscriptions()
        case .reverseResolutionDomainChanged, .walletRemoved:
            return
        }
    }
}

// MARK: - WalletConnectServiceListener
extension NotificationsService: WalletConnectServiceConnectionListener {
    func didConnect(to app: UnifiedConnectAppInfo) {
        checkNotificationsPermissions()
        
        switch app.appInfo.dAppInfoInternal {
        case .version1(let session):
            guard let walletInfo = session.walletInfo else { return }

            subscribeToWC(dAppName: app.appName,
                          wcWalletPeerId: walletInfo.peerId,
                          bridgeUrl: session.url.bridgeURL,
                          domainName: app.domain.name)
        case .version2:
            return // TODO: - WC2 Send PN on its own
        }
    }
    
    func didDisconnect(from app: UnifiedConnectAppInfo) {
        switch app.appInfo.dAppInfoInternal {
        case .version1(let session):
            guard let walletInfo = session.walletInfo else { return }
            
            unsubscribeToWC(wcWalletPeerId: walletInfo.peerId)
        case .version2:
            return // TODO: - Handled by WC2
        }
    }
    
    func didCompleteConnectionAttempt() { }
}

// MARK: - Private methods
fileprivate extension NotificationsService {
    func configure() { }
    
    func configureWC2PN() -> Bool {
        guard let clientId = try? Networking.interactor.getClientId() else {
            Debugger.printFailure("Did fail to get client id from WC2 and configure Echo.")
            return false
        }
        #if DEBUG
        Echo.configure(environment: .sandbox)
        #else
        Echo.configure(environment: .production)
        #endif
        
        return true
    }
    
    func registerForWC2PN(deviceToken: Data) {
        guard configureWC2PN() else { return }
        
        Task {
            do {                
                try await Echo.instance.register(deviceToken: deviceToken)
                Debugger.printInfo(topic: .PNs, "Did register device token with WC2")
            } catch {
                Debugger.printInfo(topic: .PNs, "Failed to register device token with WC2 with error: \(error)")
            }
        }
    }
    
    @discardableResult
    @MainActor
    func checkNotificationPayload(_ userInfo: [AnyHashable : Any],
                                  receiveState: ExternalEventReceivedState) -> UNNotificationPresentationOptions {
        if let json = userInfo as? [String : Any],
           let event = ExternalEvent(pushNotificationPayload: json) {
            appContext.analyticsService.log(event: event.analyticsEvent,
                                            withParameters: event.analyticsParameters)
            externalEventsService.receiveEvent(event,
                                               receivedState: receiveState)
            
            let defaultPresentationOptions: UNNotificationPresentationOptions = [.list, .banner, .sound]
            
            switch event {
            case .domainProfileUpdated, .mintingFinished, .domainTransferred,
                    .reverseResolutionSet, .reverseResolutionRemoved, .wcDeepLink,
                    .recordsUpdated, .parkingStatusLocal, .badgeAdded, .chatXMTPInvite:
                return defaultPresentationOptions
            case .chatMessage(let data):
                return appContext.coreAppCoordinator.isActiveState(.chatOpened(chatId: data.chatId)) ? [] : defaultPresentationOptions
            case .chatChannelMessage(let data):
                return appContext.coreAppCoordinator.isActiveState(.channelOpened(channelId: data.channelId)) ? [] : defaultPresentationOptions
            case .chatXMTPMessage(let data):
                return appContext.coreAppCoordinator.isActiveState(.chatOpened(chatId: data.topic)) ? [] : defaultPresentationOptions
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
