//
//  HomeWalletMintingInProgressSectionView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 13.08.2024.
//

import SwiftUI

struct HomeWalletMintingInProgressSectionView: View {
    
    @EnvironmentObject var tabRouter: HomeTabRouter

    let mintingDomains: [DomainDisplayInfo]
    
    var body: some View {
        if !mintingDomains.isEmpty {
            Button {
                UDVibration.buttonTap.vibrate()
                tabRouter.isShowingMintingWalletsList = true
            } label: {
                ZStack {
                    Image.mpcWalletGrid
                        .resizable()
                    Image.mpcWalletGridAccent
                        .resizable()
                        .foregroundStyle(Color.foregroundAccent)
                        .mask(AnimatedMPCWalletGridMask())
                    
                    HStack(alignment: .center, spacing: 16) {
                        ProgressView()
                            .squareFrame(24)
                            .tint(Color.foregroundDefault)
                        Text(String.Constants.pluralMintingNDomains.localized(mintingDomains.count, mintingDomains.count))
                            .textAttributes(color: .foregroundDefault,
                                            fontSize: 16,
                                            fontWeight: .medium)
                            .frame(height: 24)
                        Spacer()
                        Image.chevronRight
                            .resizable()
                            .squareFrame(24)
                            .foregroundStyle(Color.foregroundDefault)
                    }
                    .padding(.horizontal, 16)
                }
                .frame(height: 76)
                .background(
                    LinearGradient(
                        stops: [
                            Gradient.Stop(color: Color(red: 0.05, green: 0.4, blue: 1).opacity(0), location: 0.25),
                            Gradient.Stop(color: Color(red: 0.05, green: 0.4, blue: 1).opacity(0.16), location: 1.00),
                        ],
                        startPoint: UnitPoint(x: 0.5, y: 0),
                        endPoint: UnitPoint(x: 0.5, y: 1)
                    )
                )
                .background(Color.backgroundDefault)
                .cornerRadius(12)
                .overlay(
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.backgroundDefault, lineWidth: 4)
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.foregroundAccent, lineWidth: 1)
                    }
                )
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    HomeWalletMintingInProgressSectionView(mintingDomains: [])
}
