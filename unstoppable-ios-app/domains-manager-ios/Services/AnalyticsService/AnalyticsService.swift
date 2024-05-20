//
//  AnalyticsService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 12.08.2022.
//

import Foundation
import Combine

final class AnalyticsService {
       
    private var cancellables: Set<AnyCancellable> = []

    private var services: [AnalyticsServiceChildProtocol] = [AmplitudeAnalyticsService()]
    
    init(walletsDataService: WalletsDataServiceProtocol,
         wcRequestsHandlingService: WCRequestsHandlingServiceProtocol) {
        walletsDataService.walletsPublisher.receive(on: DispatchQueue.main).sink { [weak self] wallets in
            self?.updateUserPropertiesWith(wallets: wallets)
        }.store(in: &cancellables)
        wcRequestsHandlingService.addListener(self)
        setAnalyticsUserID()
    }
}

// MARK: - AnalyticsServiceProtocol
extension AnalyticsService: AnalyticsServiceProtocol {
    func log(event: Analytics.Event, withParameters eventParameters: Analytics.EventParameters?) {
        let timestamp = Date()
        let parametersDebugString = (eventParameters ?? [:]).map({ "\($0.key.rawValue) : \($0.value)" })
        Debugger.printInfo(topic: .Analytics, "Will log event: \(event.rawValue) with parameters: \(parametersDebugString)")
        
        services.forEach { (service) in
            service.log(event: event, timestamp: timestamp, withParameters: eventParameters)
        }
    }
    
    func set(userProperties: Analytics.UserProperties) {
        let parametersDebugString = userProperties.map({ "\($0.key.rawValue) : \($0.value)" })
        Debugger.printInfo(topic: .Analytics, "Will set user properties: \(parametersDebugString)")

        services.forEach { (service) in
            service.set(userProperties: userProperties)
        }
    }
}

// MARK: - WalletConnectServiceConnectionListener
extension AnalyticsService: WalletConnectServiceConnectionListener {
    func didConnect(to app: UnifiedConnectAppInfo) {
        log(event: .didConnectDApp, withParameters: getAnalyticParametersFrom(app: app))
        setNumberOfConnectedApps()
    }
    
    func didDisconnect(from app: UnifiedConnectAppInfo) {
        log(event: .didDisconnectDApp, withParameters: getAnalyticParametersFrom(app: app))
        setNumberOfConnectedApps()
    }
    
    private func getAnalyticParametersFrom(app: UnifiedConnectAppInfo) -> Analytics.EventParameters {
        [.appName : app.appName,
         .wallet: app.walletAddress,
         .hostURL: app.appUrlString]
    }
    
    private func setNumberOfConnectedApps() {
        Task {
            let appsConnected = appContext.walletConnectServiceV2.getConnectedApps()
            set(userProperties: [.numberOfConnectedDApps: String(appsConnected.count)])
        }
    }
}

// MARK: - Private methods
private extension AnalyticsService {
    func updateUserPropertiesWith(wallets: [WalletEntity]) {
        let addresses = wallets.map({ $0.address }).joined(separator: ",")
        let rrDomains = wallets.compactMap({ $0.rrDomain?.name }).joined(separator: ",")
        let numberOfBackups = appContext.udWalletsService.fetchCloudWalletClusters()
        let numberOfWallets = wallets.filter { $0.udWallet.type != .mpc }.count
        let numberOfMPCWallets = wallets.filter { $0.udWallet.type == .mpc }.count
        set(userProperties: [.walletsAddresses: addresses,
                             .reverseResolutionDomains: rrDomains,
                             .numberOfTotalWallets: String(wallets.count),
                             .numberOfWallets: String(numberOfWallets),
                             .numberOfMPCWallets: String(numberOfMPCWallets),
                             .numberOfBackups: String(numberOfBackups.count)])
        
        let domains = wallets.combinedDomains()
        var numberOfUDDomains = 0
        var numberOfParkedDomains = 0
        var numberOfENSDomains = 0
        var numberOfCOMDomains = 0
        
        for domain in domains {
            if case .parking = domain.state {
                numberOfParkedDomains += 1
            }
            let tld = domain.name.getTldName()
            if tld == Constants.ensDomainTLD {
                numberOfENSDomains += 1
            } else if tld == Constants.comDomainTLD {
                numberOfCOMDomains += 1
            } else {
                numberOfUDDomains += 1
            }
        }
        
        set(userProperties: [.numberOfTotalDomains: String(domains.count),
                             .numberOfUDDomains: String(numberOfUDDomains),
                             .numberOfParkedDomains: String(numberOfParkedDomains),
                             .numberOfENSDomains: String(numberOfENSDomains),
                             .numberOfCOMDomains: String(numberOfCOMDomains)])
    }
    
    func setAnalyticsUserID() {
        Task {
            let userID = await resolveUserID()
            services.forEach { service in
                service.set(userID: userID)
            }
        }
    }
    
    func resolveUserID() async -> String {
        await Task.sleep(seconds: 0.5) // Wait for 0.5 sec before accessing keychain to avoid error -25308. MOB-1078.
        
        let key = KeychainKey.analyticsId
        let storage = iCloudPrivateKeyStorage()
        
        // Check for existingId
        let id = storage.retrieveValue(for: key, isCritical: false)
        if let id = id {
            return id
        }
        
        let newId = UUID().uuidString
        storage.store(newId, for: key)
        
        return newId
    }
}
