//
//  PurchaseMPCWalletTakeoverView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.05.2024.
//

import SwiftUI

struct PurchaseMPCWalletTakeoverView: View {
    
    let credentialsCallback: (MPCActivateCredentials)->()

    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

// MARK: - Private methods
private extension PurchaseMPCWalletTakeoverView {
    // TODO: - Send code after takeover
}

#Preview {
    PurchaseMPCWalletTakeoverView(credentialsCallback: { _ in })
}
