//
//  AmplitudeAnalyticsService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 20.12.2023.
//

import Foundation
import Amplitude

final class AmplitudeAnalyticsService {
    
    private let instance = Amplitude.instance()
    
    init(userID: String) {
#if DEBUG
        Amplitude.instance().initializeApiKey(AmplitudeKeys.amplitudeStagingKey)
#else
        Amplitude.instance().initializeApiKey(AmplitudeKeys.amplitudeKey)
#endif
        if instance.userId == nil {
            instance.setUserId(userID)
        } else if instance.userId != userID {
            Debugger.printWarning("Different user id in Amplitude SDK and keychain")
        }
    }
}


// MARK: - AnalyticsServiceProtocol
extension AmplitudeAnalyticsService: AnalyticsServiceChildProtocol {
    func log(event: Analytics.Event, timestamp: Date, withParameters eventParameters: Analytics.EventParameters?) {
        instance.logEvent(event.rawValue, withEventProperties: eventParameters?.toCustomParameters())
    }
    
    func set(userProperties: Analytics.UserProperties) {
        var properties: [String : String] = [:]
        
        for (key, value) in userProperties {
            properties[key.rawValue] = value
        }
        
        instance.setUserProperties(properties)
    }
}
