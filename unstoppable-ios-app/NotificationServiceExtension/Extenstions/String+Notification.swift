//
//  String.swift
//  NotificationServiceExtension
//
//  Created by Oleg Kuplin on 22.07.2022.
//

import Foundation

extension String {
    
    enum Constants: String {
        case mintingFinished = "NOTIFICATION_MINTING_FINISHED"
        case mintingNFinished = "NOTIFICATION_MINTING_N_FINISHED"
        
        case domainTransferredTitle = "NOTIFICATION_DOMAIN_TRANSFERRED_TITLE"
        case domainTransferred = "NOTIFICATION_DOMAIN_TRANSFERRED"

        case recordsUpdated = "NOTIFICATION_RECORDS_UPDATED"
        case recordsUpdatedSingleAdded = "NOTIFICATION_RECORDS_UPDATED_SINGLE_ADDED"
        case recordsUpdatedSingleRemoved = "NOTIFICATION_RECORDS_UPDATED_SINGLE_REMOVED"
        case recordsUpdatedSingleUpdated = "NOTIFICATION_RECORDS_UPDATED_SINGLE_UPDATED"
        case recordsUpdatedMultipleAdded = "NOTIFICATION_RECORDS_UPDATED_MULTIPLE_ADDED"
        case recordsUpdatedMultipleRemoved = "NOTIFICATION_RECORDS_UPDATED_MULTIPLE_REMOVED"
        case recordsUpdatedMultipleUpdated = "NOTIFICATION_RECORDS_UPDATED_MULTIPLE_UPDATED"
        
        case reverseResolutionSet = "NOTIFICATION_REVERSE_RESOLUTION_SET"
        case reverseResolutionRemoved = "NOTIFICATION_REVERSE_RESOLUTION_REMOVED"

        case domainProfileUpdated = "NOTIFICATION_DOMAIN_PROFILE_UPDATED"

        case walletConnectRequest = "NOTIFICATION_WALLET_CONNECT_REQUEST"

        func localized() -> String {
            rawValue.localized()
        }
        
        func localized(_ args: CVarArg...) -> String {
            rawValue.localized(args)
        }
    }
    
}
