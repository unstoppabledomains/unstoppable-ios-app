//
//  MPCEnterCredentialsInAppView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 24.04.2024.
//

import SwiftUI

struct MPCEnterCredentialsInAppView: View {
    
    @EnvironmentObject var viewModel: ActivateMPCWalletViewModel
    
    let preFilledEmail: String?
    
    var body: some View {
        MPCEnterCredentialsView(mode: preFilledEmail == nil ? .freeInput() : .strictEmail(preFilledEmail!),
                                analyticsName: .mpcEnterCredentialsInApp,
                                credentialsCallback: didEnterCredentials,
                                forgotPasswordCallback: didPressForgotPassword)
            .padding(.top, ActivateMPCWalletFlow.viewsTopOffset)
    }
}

// MARK: - Private methods
private extension MPCEnterCredentialsInAppView {
    func didEnterCredentials(_ credentials: MPCActivateCredentials) {
        viewModel.handleAction(.didEnterCredentials(credentials))
    }
    
    func didPressForgotPassword() {
        viewModel.handleAction(.didPressForgotPassword)
    }
}

#Preview {
    MPCEnterCredentialsInAppView(preFilledEmail: nil)
}
