//
//  AnalyticsService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 12.08.2022.
//

import Foundation

final class AnalyticsService {
       
    private var services: [AnalyticsServiceChildProtocol] = [HeapAnalyticService(),
                                                             AmplitudeAnalyticsService()]
    
    init(dataAggregatorService: DataAggregatorServiceProtocol) {
        dataAggregatorService.addListener(self)
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
 
// MARK: - DataAggregatorServiceListener
extension AnalyticsService: DataAggregatorServiceListener {
    func dataAggregatedWith(result: DataAggregationResult) {
        switch result {
        case .success(let dataAggregatedResult):
            switch dataAggregatedResult {
            case .walletsListUpdated(let walletsWithInfo):
                let addresses = walletsWithInfo.map({ $0.wallet.address }).joined(separator: ",")
                set(userProperties: [.walletsAddresses: addresses])
                let rrDomains = walletsWithInfo.compactMap({ $0.displayInfo?.reverseResolutionDomain?.name }).joined(separator: ",")
                set(userProperties: [.reverseResolutionDomains: rrDomains])
            case .primaryDomainChanged(let primaryDomainName):
                set(userProperties: [.primaryDomain: primaryDomainName])
            case .domainsUpdated, .domainsPFPUpdated:
                return
            }
        case .failure:
            return
        }
    }
}

// MARK: - Private methods
private extension AnalyticsService {
    func setAnalyticsUserID() {
        Task {
            let userID = await resolveUserID()
            services.forEach { service in
                service.set(userID: userID)
            }
        }
    }
    
    func resolveUserID() async -> String {
        try? await Task.sleep(seconds: 0.5) // Wait for 0.5 sec before accessing keychain to avoid error -25308. MOB-1078.
        
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
