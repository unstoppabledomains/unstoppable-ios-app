//
//  MPCEnterCredentialsReconnectView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 23.05.2024.
//

import SwiftUI

struct MPCEnterCredentialsReconnectView: View {
    @EnvironmentObject var viewModel: ReconnectMPCWalletViewModel
    
    let email: String
    
    var body: some View {
        MPCEnterCredentialsView(mode: .strictEmail(email),
                                analyticsName: .mpcEnterCredentialsReconnect,
                                credentialsCallback: didEnterCredentials)
        .padding(.top, ActivateMPCWalletFlow.viewsTopOffset)
    }
}

// MARK: - Private methods
private extension MPCEnterCredentialsReconnectView {
    func didEnterCredentials(_ credentials: MPCActivateCredentials) {
        viewModel.handleAction(.didEnterCredentials(credentials))
    }
}

#Preview {
    MPCEnterCredentialsReconnectView(email: "qq@qq.qq")
}

