//
//  PurchaseMPCWalletTakeoverProgressInAppView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 30.05.2024.
//

import SwiftUI

struct PurchaseMPCWalletTakeoverProgressInAppView: View {
    
    @EnvironmentObject var viewModel: PurchaseMPCWalletViewModel
    let credentials: MPCTakeoverCredentials
    
    var body: some View {
        PurchaseMPCWalletTakeoverProgressView(analyticsName: .mpcPurchaseTakeoverProgressInApp,
                                              credentials: credentials,
                                              finishCallback: didFinishTakeover)
        .padding(.top, ActivateMPCWalletFlow.viewsTopOffset)
        .navigationBarBackButtonHidden(true)
    }
}

// MARK: - Private methods
private extension PurchaseMPCWalletTakeoverProgressInAppView {
    func didFinishTakeover() {
        viewModel.handleAction(.didFinishTakeover)
    }
}

#Preview {
    PurchaseMPCWalletTakeoverProgressInAppView(credentials: .init(email: "qq@qq.qq",
                                                                  password: ""))
}
