//
//  ChannelFeedEmptyView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 20.02.2024.
//

import SwiftUI

struct ChannelFeedEmptyView: View {
    var body: some View {
        ChatCommonEmptyView(icon: .messageCircleIcon24,
                            title: String.Constants.messagingChatEmptyTitle.localized(),
                            subtitle: String.Constants.messagingChannelEmptyMessage.localized())
    }
}

#Preview {
    ChannelFeedEmptyView()
}
