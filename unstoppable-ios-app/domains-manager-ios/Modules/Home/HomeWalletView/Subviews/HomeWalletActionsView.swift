//
//  HomeWalletActionsView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 16.01.2024.
//

import SwiftUI

struct HomeWalletActionsView: View {
    
    let actionCallback: (HomeWalletView.WalletAction)->()
    let subActionCallback: (HomeWalletView.WalletSubAction)->()
    
    var body: some View {
        HStack {
            ForEach(HomeWalletView.WalletAction.allCases, id: \.self) { action in
                walletActionView(for: action)
            }
        }
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
}

// MARK: - Private methods
private extension HomeWalletActionsView {
    
    @ViewBuilder
    func walletActionView(for action: HomeWalletView.WalletAction) -> some View {
        if action.subActions.isEmpty {
            walletActionButtonView(title: action.title,
                                   icon: action.icon) {
                actionCallback(action)
            }
        } else {
            Menu {
                ForEach(action.subActions, id: \.self) { subAction in
                    Button {
                        UDVibration.buttonTap.vibrate()
                        subActionCallback(subAction)
                    } label: {
                        Label(
                            title: { Text(subAction.title) },
                            icon: { subAction.icon }
                        )
                    }
                }
            } label: {
                walletActionButtonView(title: action.title,
                                       icon: action.icon)
            }
        }
    }
    
    @ViewBuilder
    func walletActionButtonView(title: String,
                                icon: Image,
                                callback: EmptyCallback? = nil) -> some View {
        Button {
            UDVibration.buttonTap.vibrate()
            callback?()
        } label: {
            VStack(spacing: 4) {
                icon
                    .resizable()
                    .renderingMode(.template)
                    .squareFrame(20)
                Text(title)
                    .font(.currentFont(size: 13, weight: .medium))
                    .frame(height: 20)
            }
            .foregroundColor(.foregroundAccent)
            .frame(height: 72)
            .frame(minWidth: 0, maxWidth: .infinity)
            .background(Color.backgroundOverlay)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(lineWidth: 1)
                    .foregroundStyle(Color.borderMuted)
            }
        }
        .buttonStyle(.plain)
        .withoutAnimation()
    }
    
}

#Preview {
    HomeWalletActionsView(actionCallback: { _ in },
                          subActionCallback: { _ in })
}
