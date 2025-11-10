//
//  UpdateNotificationView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 10.11.2025.
//

import SwiftUI

struct UpdateNotificationView: View {
    
    @StateObject var viewModel: UpdateNotificationViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var dontShowAgain = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Icon
                HStack {
                    Spacer()
                    Image(systemName: "exclamationmark.triangle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 40)
                        .foregroundColor(.foregroundWarning)
                    Spacer()
                }
                .padding(.top, 8)
                
                // Title
                Text(String.Constants.updateNotificationTitle.localized())
                    .font(.currentFont(size: 24, weight: .bold))
                    .foregroundColor(.foregroundDefault)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .multilineTextAlignment(.center)
                
                // Intro
                Text(String.Constants.updateNotificationIntro.localized())
                    .font(.currentFont(size: 16))
                    .foregroundColor(.foregroundDefault)
                    .multilineTextAlignment(.leading)
                
                // What's changing
                Text(String.Constants.updateNotificationWhatsChanging.localized())
                    .font(.currentFont(size: 16))
                    .foregroundColor(.foregroundDefault)
                    .multilineTextAlignment(.leading)
                
                // MPC Wallets section
                if viewModel.hasMPCWallets {
                    Text(String.Constants.updateNotificationMPCWallets.localized())
                        .font(.currentFont(size: 16))
                        .foregroundColor(.foregroundDefault)
                        .multilineTextAlignment(.leading)
                }
                
                // Private Keys section
                if viewModel.hasPrivateKeyWallets {
                    Text(String.Constants.updateNotificationPrivateKeys.localized())
                        .font(.currentFont(size: 16))
                        .foregroundColor(.foregroundDefault)
                        .multilineTextAlignment(.leading)
                }
                
                // Test App section
                Text(String.Constants.updateNotificationTestApp.localized())
                    .font(.currentFont(size: 16))
                    .foregroundColor(.foregroundDefault)
                    .multilineTextAlignment(.leading)
                
                // Contact section
                Button(action: {
                    openEmailClient()
                }) {
                    Text(String.Constants.updateNotificationContact.localized())
                        .font(.currentFont(size: 16))
                        .foregroundColor(.foregroundDefault)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                
                // Checkbox
                Toggle(isOn: $dontShowAgain) {
                    Text(String.Constants.dontShowAgain.localized())
                        .font(.currentFont(size: 16))
                        .foregroundColor(.foregroundDefault)
                }
                .tint(.foregroundAccent)
                .padding(.top, 8)
                
                // Got It Button
                Button(action: {
                    viewModel.didTapGotIt(dontShowAgain: dontShowAgain)
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text(String.Constants.gotIt.localized())
                        .font(.currentFont(size: 16, weight: .semibold))
                        .foregroundColor(.foregroundOnEmphasis)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.backgroundAccentEmphasis)
                        .cornerRadius(12)
                }
                .padding(.top, 8)
                
                Spacer(minLength: 16)
            }
            .padding(.horizontal, 16)
        }
        .background(Color.backgroundDefault)
    }
    
    private func openURL(_ url: URL) {
        UIApplication.shared.open(url)
    }
    
    private func openEmailClient() {
        let email = "mobile-team@unstoppabledomains.com"
        if let url = URL(string: "mailto:\(email)") {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    PresentAsModalPreviewView {
        UpdateNotificationView(viewModel: UpdateNotificationViewModel())
            .presentationDetents([.large])
    }
}

