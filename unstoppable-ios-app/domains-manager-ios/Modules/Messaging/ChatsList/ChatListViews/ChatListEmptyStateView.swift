//
//  ChatListEmptyStateView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 20.02.2024.
//

import SwiftUI

struct ChatListEmptyStateView: View {
    let title: String
    let subtitle: String
    let icon: Image
    let actionButtonConfiguration: ActionButtonConfiguration?
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                icon
                    .resizable()
                    .squareFrame(32)
                VStack(spacing: 8) {
                    Text(title)
                        .font(.currentFont(size: 20, weight: .bold))
                    Text(subtitle)
                        .font(.currentFont(size: 16))
                }
            }
            .foregroundStyle(Color.foregroundSecondary)
            .multilineTextAlignment(.center)
            
            actionButtonForCurrentConfiguration()
        }
        .frame(maxWidth: .infinity)
        .frame(height: 400)
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }
}

// MARK: - Private methods
private extension ChatListEmptyStateView {
    @ViewBuilder
    func actionButtonForCurrentConfiguration() -> some View {
        if let actionButtonConfiguration {
            UDButtonView(text: actionButtonConfiguration.buttonTitle,
                         icon: actionButtonConfiguration.buttonIcon,
                         style: actionButtonConfiguration.buttonStyle,
                         callback: actionButtonConfiguration.buttonCallback)
        }
    }
}

// MARK: - Open methods
extension ChatListEmptyStateView {
    struct ActionButtonConfiguration {
        let buttonTitle: String
        let buttonIcon: Image
        let buttonStyle: UDButtonStyle
        let buttonCallback: MainActorCallback
    }
}

#Preview {
    ChatListEmptyStateView(title: "Title",
                           subtitle: "Subtitle",
                           icon: .messageCircleIcon24,
                           actionButtonConfiguration: .init(buttonTitle: "Action",
                                                            buttonIcon: .messagesIcon,
                                                            buttonStyle: .medium(.raisedPrimary),
                                                            buttonCallback: { }))
}
