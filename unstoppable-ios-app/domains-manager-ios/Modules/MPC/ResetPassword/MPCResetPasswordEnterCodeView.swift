//
//  MPCResetPasswordEnterCodeView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 24.10.2024.
//

import SwiftUI

struct MPCResetPasswordEnterCodeView: View {
    @Environment(\.mpcWalletsService) private var mpcWalletsService
    @EnvironmentObject var viewModel: MPCResetPasswordViewModel
    
    let email: String
    
    var body: some View {
        MPCEnterCodeView(analyticsName: .mpcResetPasswordEnterCode,
                         email: email,
                         resendAction: resendCode,
                         enterCodeCallback: didEnterCode)
        .padding(.top, ActivateMPCWalletFlow.viewsTopOffset)
    }
}

// MARK: - Private methods
private extension MPCResetPasswordEnterCodeView {
    func didEnterCode(_ code: String) {
        viewModel.handleAction(.didEnterCode(code))
    }
    
    func resendCode(email: String) async throws {
        try await mpcWalletsService.sendBootstrapCodeTo(email: email)
    }
}

#Preview {
    MPCResetPasswordEnterCodeView(email: "")
}
