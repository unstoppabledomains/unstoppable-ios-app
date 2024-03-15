//
//  ChannelFeedRowView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 20.02.2024.
//

import SwiftUI

struct ChannelFeedRowView: View, ViewAnalyticsLogger {
    
    @Environment(\.analyticsViewName) var analyticsName
    @Environment(\.analyticsAdditionalProperties) var additionalAppearAnalyticParameters
    
    let feed: MessagingNewsChannelFeed
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            feedContentView()
            Text(MessageDateFormatter.formatMessageDate(feed.time))
                .font(.currentFont(size: 11))
                .foregroundStyle(Color.foregroundSecondary)
        }
        .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 64))
    }
    
}

// MARK: - Private methods
private extension ChannelFeedRowView {
    @ViewBuilder
    func feedContentView() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(feed.title)
                .font(.currentFont(size: 16, weight: .medium))
            Text(feed.message)
                .font(.currentFont(size: 16))
            if let link = feed.link {
                LineView(direction: .horizontal)
                    .foregroundStyle(Color.borderMuted)
                feedLinkButtonView(link)
            }
        }
        .padding(.init(horizontal: 12))
        .padding(.init(vertical: 6))
        .foregroundStyle(Color.foregroundDefault)
        .background(Color.backgroundMuted2)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    @ViewBuilder
    func feedLinkButtonView(_ link: URL) -> some View {
        Button {
            logButtonPressedAnalyticEvents(button: .learnMoreChannelFeed,
                                           parameters: [.feedName: feed.title])
            Task {
                await openLink(.generic(url: link.absoluteString))
            }
        } label: {
            Text(String.Constants.learnMore.localized())
                .foregroundStyle(Color.foregroundAccent)
                .frame(height: 24)
                .frame(maxWidth: .infinity)
        }
        .padding(EdgeInsets(top: 0, leading: 0, bottom: 6, trailing: 0))
        .buttonStyle(.plain)
    }
}

#Preview {
    ChannelFeedRowView(feed: MockEntitiesFabric.Messaging.mockChannelFeed(title: "Title", message: "Preview", withLink: true))
}
