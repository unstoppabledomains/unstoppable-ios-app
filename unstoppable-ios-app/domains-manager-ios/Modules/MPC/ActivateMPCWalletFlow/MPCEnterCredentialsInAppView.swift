//
//  MPCEnterCredentialsInAppView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 24.04.2024.
//

import SwiftUI

struct MPCEnterCredentialsInAppView: View {
    
    @EnvironmentObject var viewModel: ActivateMPCWalletViewModel

    var body: some View {
        MPCEnterCredentialsView(withTopPadding: false,
                                credentialsCallback: didEnterCredentials)
    }
}

// MARK: - Private methods
private extension MPCEnterCredentialsInAppView {
    func didEnterCredentials(_ credentials: MPCActivateCredentials) {
        viewModel.handleAction(.didEnterCredentials(credentials))
    }
}

#Preview {
    MPCEnterCredentialsInAppView()
}
