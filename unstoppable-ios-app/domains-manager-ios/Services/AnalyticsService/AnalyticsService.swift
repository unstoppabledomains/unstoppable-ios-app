//
//  AnalyticsService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 12.08.2022.
//

import UIKit
import CoreTelephony

final class AnalyticsService {
       
    private var servicesHolder: ServicesHolder!
    private var services: [AnalyticsServiceChildProtocol] {
        get async {
            let holder = await getServicesHolder()
            return await holder.services
        }
    }
    private var createServiceHolderTask: Task<ServicesHolder, Never>?
    
    init(dataAggregatorService: DataAggregatorServiceProtocol) {
        dataAggregatorService.addListener(self)
    }
    
}

// MARK: - AnalyticsServiceProtocol
extension AnalyticsService: AnalyticsServiceProtocol {
    func log(event: Analytics.Event, withParameters eventParameters: Analytics.EventParameters?) {
        let timestamp = Date()
        Task  {
            let parametersDebugString = (eventParameters ?? [:]).map({ "\($0.key.rawValue) : \($0.value)" })
            Debugger.printInfo(topic: .Analytics, "Will log event: \(event.rawValue) with parameters: \(parametersDebugString)")
            
            let defaultProperties = self.defaultProperties
            await services.forEach { (service) in
                service.log(event: event, timestamp: timestamp, withParameters: (eventParameters ?? [:]).adding(defaultProperties))
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
    func getServicesHolder() async -> ServicesHolder {
        if let servicesHolder {
            return servicesHolder
        } else if let task = createServiceHolderTask {
            return await task.value
        }
        
        let createServiceHolderTask: Task<ServicesHolder, Never> = Task {
            await ServicesHolder()
        }
        self.createServiceHolderTask = createServiceHolderTask
        let servicesHolder = await createServiceHolderTask.value
        self.servicesHolder = servicesHolder
        self.createServiceHolderTask = nil
        return servicesHolder
    }
    
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
        private(set) var services: [AnalyticsServiceChildProtocol] = []
        
        init() async {
            let userID = await resolveUserID()
            services = [HeapAnalyticService(userID: userID),
                        AmplitudeAnalyticsService(userID: userID)]
        }
        
        private func resolveUserID() async -> String {
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
}
