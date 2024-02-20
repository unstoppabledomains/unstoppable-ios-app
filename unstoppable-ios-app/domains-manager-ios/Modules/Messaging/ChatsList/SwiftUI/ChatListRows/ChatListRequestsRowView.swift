//
//  ChatListRequestsRowView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 20.02.2024.
//

import SwiftUI

struct ChatListRequestsRowView: View {
    
    let dataType: ChatsList.DataType
    let numberOfRequests: Int
    
    var body: some View {
        HStack(spacing: 16) {
            iconView()
            labelsStackView()
            Spacer()
            Image.cellChevron
                .resizable()
                .squareFrame(20)
                .foregroundStyle(Color.foregroundMuted)
        }
        .frame(height: 60)
    }
    
}

// MARK: - Private methods
private extension ChatListRequestsRowView {
    @ViewBuilder
    func iconView() -> some View {
        ZStack {
            Color.backgroundMuted2
            currentIcon.resizable()
                .squareFrame(20)
                .foregroundStyle(Color.foregroundDefault)
        }
        .overlay {
            Circle()
                .stroke(lineWidth: 1)
                .foregroundStyle(Color.borderSubtle)
        }
        .squareFrame(40)
        .clipShape(Circle())
    }
    
    var currentIcon: Image {
        switch dataType {
        case .chats, .communities:
            return .chatRequestsIcon
        case .channels:
            return .alertOctagon24
        }
    }
    
    @ViewBuilder
    func labelsStackView() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(currentTitle)
                .font(.currentFont(size: 16, weight: .medium))
                .foregroundStyle(Color.foregroundDefault)
            Text(currentSubtitle)
                .font(.currentFont(size: 14))
                .foregroundStyle(Color.foregroundSecondary)
        }
    }
    
    var currentTitle: String {
        switch dataType {
        case .chats, .communities:
            return String.Constants.chatRequests.localized()
        case .channels:
            return String.Constants.spam.localized()
        }
    }
    
    var currentSubtitle: String {
        switch dataType {
        case .chats, .communities:
            return String.Constants.pluralNPeopleYouMayKnow.localized(numberOfRequests, numberOfRequests)
        case .channels:
            return String.Constants.pluralNMessages.localized(numberOfRequests, numberOfRequests)
        }
    }
}

#Preview {
    ChatListRequestsRowView(dataType: .chats,
                            numberOfRequests: 2)
}
