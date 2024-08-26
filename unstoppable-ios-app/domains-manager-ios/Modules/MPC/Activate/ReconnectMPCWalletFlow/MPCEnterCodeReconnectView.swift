//
//  MPCEnterCodeReconnectView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 23.05.2024.
//

import SwiftUI

struct MPCEnterCodeReconnectView: View {
    @Environment(\.mpcWalletsService) private var mpcWalletsService
    @EnvironmentObject var viewModel: ReconnectMPCWalletViewModel
    
    let email: String
    
    var body: some View {
        MPCEnterCodeView(analyticsName: .mpcEnterCodeInApp,
                         email: email, 
                         resendAction: resendCode,
                         enterCodeCallback: didEnterCode)
        .padding(.top, ActivateMPCWalletFlow.viewsTopOffset)
    }
}

// MARK: - Private methods
private extension MPCEnterCodeReconnectView {
    func didEnterCode(_ code: String) {
        viewModel.handleAction(.didEnterCode(code))
    }
    
    func resendCode(email: String) async throws {
        try await mpcWalletsService.sendBootstrapCodeTo(email: email)
    }
}

#Preview {
    MPCEnterCodeReconnectView(email: "")
}

