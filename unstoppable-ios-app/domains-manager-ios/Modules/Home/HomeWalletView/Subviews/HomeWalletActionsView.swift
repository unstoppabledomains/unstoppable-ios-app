//
//  HomeWalletActionsView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 16.01.2024.
//

import SwiftUI

struct HomeWalletActionsView<Action: HomeWalletActionItem>: View, ViewAnalyticsLogger {
   
    @Environment(\.analyticsViewName) var analyticsName
    @Environment(\.analyticsAdditionalProperties) var additionalAppearAnalyticParameters
    let actionCallback: (Action)->()
    let subActionCallback: (Action.SubAction)->()
    
    var body: some View {
        HStack {
            ForEach(Array(Action.allCases), id: \.rawValue) { action in
                walletActionView(for: action)
            }
        }
    }
}

// MARK: - Private methods
private extension HomeWalletActionsView {
    
    @ViewBuilder
    func walletActionView(for action: Action) -> some View {
        if action.subActions.isEmpty {
            walletActionButtonView(title: action.title,
                                   icon: action.icon) {
                logButtonPressedAnalyticEvents(button: action.analyticButton)
                actionCallback(action)
            }
        } else {
            Menu {
                ForEach(action.subActions, id: \.rawValue) { subAction in
                    Button(role: subAction.isDestructive ? .destructive : .cancel) {
                        UDVibration.buttonTap.vibrate()
                        subActionCallback(subAction)
                        logButtonPressedAnalyticEvents(button: subAction.analyticButton)
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
            .onButtonTap {
                logButtonPressedAnalyticEvents(button: action.analyticButton)
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
    HomeWalletActionsView<HomeWalletView.WalletAction>(actionCallback: { _ in },
                          subActionCallback: { _ in })
}
