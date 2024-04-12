//
//  FirebasePreferencesStorageService.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 02.11.2023.
//

import Foundation

final class PurchaseDomainsPreferencesStorage {
    
    static let shared = PurchaseDomainsPreferencesStorage()
    
    @PublishingAppStorage("eComCheckoutData")
    var checkoutData: PurchaseDomainsCheckoutData = PurchaseDomainsCheckoutData()

}
