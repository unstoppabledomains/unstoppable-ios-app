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
    let buttonTitle: String
    let buttonIcon: Image
    let buttonStyle: UDButtonStyle
    let buttonCallback: MainActorCallback
    
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
            
            UDButtonView(text: buttonTitle,
                         icon: buttonIcon,
                         style: buttonStyle,
                         callback: buttonCallback)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 400)
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }
}

#Preview {
    ChatListEmptyStateView(title: "Title",
                           subtitle: "Subtitle",
                           icon: .messageCircleIcon24,
                           buttonTitle: "Action",
                           buttonIcon: .messagesIcon,
                           buttonStyle: .medium(.raisedPrimary),
                           buttonCallback: { })
}
