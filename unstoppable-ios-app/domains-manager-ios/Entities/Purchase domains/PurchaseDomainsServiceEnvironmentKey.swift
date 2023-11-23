//
//  PurchaseDomainsServiceEnvironmentKey.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 16.11.2023.
//

import Foundation
import SwiftUI

private struct PurchaseDomainsServiceKey: EnvironmentKey {
    static let defaultValue = appContext.purchaseDomainsService 
}

extension EnvironmentValues {
    var purchaseDomainsService: PurchaseDomainsServiceProtocol {
        get { self[PurchaseDomainsServiceKey.self] }
        set { self[PurchaseDomainsServiceKey.self] = newValue }
    }
}
