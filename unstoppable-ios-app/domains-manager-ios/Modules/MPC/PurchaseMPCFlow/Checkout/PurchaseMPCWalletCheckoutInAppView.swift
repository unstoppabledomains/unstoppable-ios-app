//
//  PurchaseMPCWalletCheckoutInAppView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 30.05.2024.
//

import SwiftUI

struct PurchaseMPCWalletCheckoutInAppView: View {
    
    let credentials: MPCPurchaseUDCredentials
    
    var body: some View {
        PurchaseMPCWalletCheckoutView(analyticsName: .mpcPurchaseCheckoutInApp,
                                      credentials: credentials,
                                      purchaseStateCallback: { state in
            
        }, purchasedCallback: { result in
            
        })
    }
    
}

// MARK: - Private methods
private extension PurchaseMPCWalletCheckoutInAppView {
    
}

#Preview {
    PurchaseMPCWalletCheckoutInAppView(credentials: .init(email: "qq@qq.qq"))
}
