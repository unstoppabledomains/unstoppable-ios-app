//
//  PurchaseDomainsPreferencesStorageEnvironmentKey.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 16.11.2023.
//

import Foundation
import SwiftUI

private struct PurchaseDomainsPreferencesStorageServiceKey: EnvironmentKey {
    static let defaultValue = PurchaseDomainsPreferencesStorage.shared
}

extension EnvironmentValues {
    var purchaseDomainsPreferencesStorage: PurchaseDomainsPreferencesStorage {
        get { self[PurchaseDomainsPreferencesStorageServiceKey.self] }
        set { self[PurchaseDomainsPreferencesStorageServiceKey.self] = newValue }
    }
}
