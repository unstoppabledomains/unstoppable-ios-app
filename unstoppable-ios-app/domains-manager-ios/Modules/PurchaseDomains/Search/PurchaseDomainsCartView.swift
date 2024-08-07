//
//  PurchaseDomainsCartView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.08.2024.
//

import SwiftUI

struct PurchaseDomainsCartView: View {
    
    @EnvironmentObject private var localCart: PurchaseDomains.LocalCart

    var body: some View {
        Text("\(localCart.domains.count) domains in cart")
    }
}

#Preview {
    PurchaseDomainsCartView()
        .environmentObject(PurchaseDomains.LocalCart())
}
