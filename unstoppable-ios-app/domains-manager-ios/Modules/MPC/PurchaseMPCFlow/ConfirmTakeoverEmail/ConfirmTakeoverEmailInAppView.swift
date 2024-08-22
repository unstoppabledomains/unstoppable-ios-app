//
//  ConfirmTakeoverEmailView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 22.08.2024.
//

import SwiftUI

struct ConfirmTakeoverEmailInAppView: View {
    @Environment(\.claimMPCWalletService) private var claimMPCWalletService
    @EnvironmentObject var viewModel: PurchaseMPCWalletViewModel
    
    let email: String
    
    var body: some View {
        MPCEnterCodeView(analyticsName: .mpcConfirmCodeInApp,
                         email: email, 
                         resendAction: resendCode,
                         enterCodeCallback: didEnterCode)
        .padding(.top, ActivateMPCWalletFlow.viewsTopOffset)
    }
}

// MARK: - Private methods
private extension ConfirmTakeoverEmailInAppView {
    func didEnterCode(_ code: String) {
        viewModel.handleAction(.didConfirmTakeoverEmail(code: code))
    }
    
    func resendCode(email: String) async throws {
        try await claimMPCWalletService.sendVerificationCodeTo(email: email)
    }
}

#Preview {
    ConfirmTakeoverEmailInAppView(email: "qq@qq.qq")
}
