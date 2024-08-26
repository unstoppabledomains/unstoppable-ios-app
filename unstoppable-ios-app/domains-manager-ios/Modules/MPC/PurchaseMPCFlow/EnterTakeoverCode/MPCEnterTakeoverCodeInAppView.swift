//
//  MPCEnterTakeoverCodeInAppView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 22.08.2024.
//

import SwiftUI

struct MPCEnterTakeoverCodeInAppView: View {
    @Environment(\.claimMPCWalletService) private var claimMPCWalletService
    @EnvironmentObject var viewModel: PurchaseMPCWalletViewModel
    
    let email: String
    
    var body: some View {
        MPCEnterCodeView(analyticsName: .mpcConfirmCodeInApp,
                         email: email, 
                         resendAction: resendCode,
                         enterCodeCallback: didEnterCode)
    }
}

// MARK: - Private methods
private extension MPCEnterTakeoverCodeInAppView {
    func didEnterCode(_ code: String) {
        viewModel.handleAction(.didEnterTakeover(code: code))
    }
    
    func resendCode(email: String) async throws {
        try await claimMPCWalletService.sendVerificationCodeTo(email: email)
    }
}

#Preview {
    MPCEnterTakeoverCodeInAppView(email: "qq@qq.qq")
}

