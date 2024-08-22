//
//  MPCEnterCodeInAppAfterClaimView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 22.08.2024.
//

import SwiftUI

struct MPCEnterCodeInAppAfterClaimView: View {
    @Environment(\.mpcWalletsService) private var mpcWalletsService
    @EnvironmentObject var viewModel: PurchaseMPCWalletViewModel
    
    let email: String
    @State private var didSendCode = false
    
    var body: some View {
        MPCEnterCodeView(analyticsName: .mpcEnterCodeInApp,
                         email: email,
                         resendAction: resendCode,
                         enterCodeCallback: didEnterCode)
        .padding(.top, ActivateMPCWalletFlow.viewsTopOffset)
        .onAppear(perform: onAppear)
    }
}

// MARK: - Private methods
private extension MPCEnterCodeInAppAfterClaimView {
    func onAppear() {
        guard !didSendCode else { return }
        
        didSendCode = true
        Task {
            try? await resendCode(email: email)
        }
    }
    
    func didEnterCode(_ code: String) {
        viewModel.handleAction(.didEnterActivation(code: code))
    }
    
    func resendCode(email: String) async throws {
        try await mpcWalletsService.sendBootstrapCodeTo(email: email)
    }
}

#Preview {
    MPCEnterCodeInAppAfterClaimView(email: "")
}

