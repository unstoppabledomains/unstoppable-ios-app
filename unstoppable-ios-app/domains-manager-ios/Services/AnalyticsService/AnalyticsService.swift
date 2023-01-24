//
//  AnalyticsService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 12.08.2022.
//

import UIKit
import CoreTelephony

final class AnalyticsService {
       
    private let servicesHolder = ServicesHolder()
    private var services: [AnalyticsServiceProtocol] {
        get async { await servicesHolder.services }
    }
    
    init(dataAggregatorService: DataAggregatorServiceProtocol) {
        dataAggregatorService.addListener(self)
    }
    
}

// MARK: - AnalyticsServiceProtocol
extension AnalyticsService: AnalyticsServiceProtocol {
    func log(event: Analytics.Event, withParameters eventParameters: Analytics.EventParameters?) {
        Task  {
            let defaultProperties = self.defaultProperties
            await services.forEach { (service) in
                service.log(event: event, withParameters: (eventParameters ?? [:]).adding(defaultProperties))
            }
        }
    }
    
    func set(userProperties: Analytics.UserProperties) {
        Task  {
            await services.forEach { (service) in
                service.set(userProperties: userProperties)
            }
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
    var defaultProperties: Analytics.EventParameters {
        [.carrier : carrierName,
         .platform: "iOS " + UIDevice.current.systemVersion,
         .phoneModel: UIDevice.current.modelCode ?? "Unknown",
         .iosVendorId: UIDevice.current.identifierForVendor?.uuidString ?? "Unknown",
         .appName: Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ?? "Unknown",
         .appVersion: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown",
         .ip: publicIP() ?? "Unknown"]
    }
    
    var carrierName: String {
        CTTelephonyNetworkInfo().serviceSubscriberCellularProviders?.values.compactMap({ $0.carrierName }).joined(separator: ", ") ?? ""
    }
    
    func publicIP() -> String? {
        do {
            let url = URL(string: "https://icanhazip.com/")!
            let publicIP = try String(contentsOf: url,
                                      encoding: .utf8)
                .trimmingCharacters(in: .whitespaces)
            return publicIP
        }
        catch {
            Debugger.printFailure("Failed to get public IP")
            return nil
        }
    }
}

// MARK: - Private methods
private extension AnalyticsService {
    actor ServicesHolder {
        lazy var services: [AnalyticsServiceProtocol] = {
            [HeapAnalyticService(userID: resolveUserID())]
        }()
        
        func resolveUserID() -> String {
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
}
