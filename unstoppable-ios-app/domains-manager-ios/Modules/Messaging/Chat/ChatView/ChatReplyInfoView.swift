//
//  ChatReplyInfoView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.02.2024.
//

import SwiftUI

struct ChatReplyInfoView: View, ViewAnalyticsLogger {
    
    @EnvironmentObject var viewModel: ChatViewModel
    @Environment(\.analyticsViewName) var analyticsName
    @Environment(\.analyticsAdditionalProperties) var additionalAppearAnalyticParameters
    
    let messageToReply: MessagingChatMessageDisplayInfo
    
    var body: some View {
        HStack(spacing: 20) {
            replyIndicatorView()
            LineView(direction: .vertical)
                .padding(.init(vertical: 4))
            clickableMessageDescriptionView()
            Spacer()
            removeReplyView()
        }
        .foregroundStyle(Color.foregroundAccent)
        .frame(height: 40)
        .padding(.init(horizontal: 16))
            .background(.regularMaterial)
    }
}

// MARK: - Private methods
private extension ChatReplyInfoView {
    func getNameOfMessageSender() -> String {
        messageToReply.senderType.userDisplayInfo.displayName
    }
    
    func getMessageContentDescription() -> String {
        messageToReply.type.getContentDescriptionText()
    }
}

// MARK: - Private methods
private extension ChatReplyInfoView {
    @ViewBuilder
    func clickableMessageDescriptionView() -> some View {
        Button {
            UDVibration.buttonTap.vibrate()
            logButtonPressedAnalyticEvents(button: .jumpToMessageToReply)
            withAnimation {
                viewModel.didTapJumpToReplyButton()
            }
        } label: {
            messageDescriptionView()
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    func messageDescriptionView() -> some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Reply to \(getNameOfMessageSender())")
                    .font(.currentFont(size: 14, weight: .medium))
                Spacer()
            }
            HStack {
                Text(getMessageContentDescription())
                    .foregroundStyle(Color.foregroundDefault)
                    .font(.currentFont(size: 14))
                Spacer()
            }
        }
        .multilineTextAlignment(.leading)
        .lineLimit(1)
    }
    
    @ViewBuilder
    func replyIndicatorView() -> some View {
        Image(systemName: "arrowshape.turn.up.left")
            .font(.title2)
    }
    
    @ViewBuilder
    func removeReplyView() -> some View {
        Button {
            logButtonPressedAnalyticEvents(button: .cancelReply)
            UDVibration.buttonTap.vibrate()
            withAnimation {
                viewModel.didTapRemoveReplyButton()
            }
        } label: {
            Image(systemName: "xmark")
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ChatReplyInfoView(messageToReply: MockEntitiesFabric.Messaging.createTextMessage(text: "Hello kjsdfh dflj hsdfkjhsdkf hsdkj fh skdjfh sdkjfh", isThisUser: false))
}
