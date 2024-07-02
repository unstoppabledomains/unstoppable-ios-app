//
//  HomeActivityEmptyView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 10.04.2024.
//

import SwiftUI

struct HomeActivityEmptyView: View, ViewAnalyticsLogger {
    
    @EnvironmentObject var tabRouter: HomeTabRouter
    @Environment(\.analyticsViewName) var analyticsName: Analytics.ViewName

    var body: some View {
        VStack(spacing: 24) {
            Image.brushSparkle
                .resizable()
                .squareFrame(48)
            Text(String.Constants.noTransactionsYet.localized())
                .font(.currentFont(size: 22, weight: .bold))
            UDButtonView(text: String.Constants.sendCrypto.localized(),
                         icon: .paperPlaneTopRight,
                         style: .medium(.raisedTertiary),
                         callback: {
                logButtonPressedAnalyticEvents(button: .qrCode)
                if case .wallet(let wallet) = tabRouter.profile {
                    tabRouter.sendCryptoInitialData = .init(sourceWallet: wallet)
                }
            })
        }
        .foregroundStyle(Color.foregroundSecondary)
        .padding(.horizontal, 16)
        .backgroundStyle(Color.clear)
    }
}

#Preview {
    HomeActivityEmptyView()
}
