//
//  ChatCreateMessagingProfileView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 19.02.2024.
//

import SwiftUI

struct ChatCreateMessagingProfileView: View {
    var body: some View {
        VStack(alignment: .center, spacing: 32) {
            VStack(alignment: .center, spacing: 24) {
                Image.createMessagingProfileIllustration
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                Text(String.Constants.messagingIntroductionTitle.localized())
                    .font(.currentFont(size: 32, weight: .bold))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            Line(direction: .horizontal)
                .stroke(style: StrokeStyle(lineWidth: 1,
                                           dash: [5]))
                .foregroundStyle(Color.borderMuted)
                .frame(height: 1)
            
            VStack(alignment: .leading, spacing: 16) {
                ForEach(CreateProfileHint.allCases, id: \.self) { hint in
                    HStack(spacing: 16) {
                        hint.icon
                            .resizable()
                            .squareFrame(24)
                            .foregroundStyle(Color.foregroundAccent)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(hint.title)
                                .font(.currentFont(size: 16, weight: .semibold))
                                .foregroundStyle(Color.foregroundDefault)
                            Text(hint.subtitle)
                                .font(.currentFont(size: 14))
                                .foregroundStyle(Color.foregroundSecondary)
                        }
                    }
                    .padding(.init(horizontal: 24))
                }
            }
        }
    }
}

// MARK: - Private methods
private extension ChatCreateMessagingProfileView {
    enum CreateProfileHint: CaseIterable {
        case stayInLoop, privacy, noFee
        
        var title: String {
            switch self {
            case .stayInLoop:
                return String.Constants.messagingIntroductionHint1Title.localized()
            case .privacy:
                return String.Constants.messagingIntroductionHint2Title.localized()
            case .noFee:
                return String.Constants.messagingIntroductionHint3Title.localized()
            }
        }
        
        var subtitle: String {
            switch self {
            case .stayInLoop:
                return String.Constants.messagingIntroductionHint1Subtitle.localized()
            case .privacy:
                return String.Constants.messagingIntroductionHint2Subtitle.localized()
            case .noFee:
                return String.Constants.messagingIntroductionHint3Subtitle.localized()
            }
        }
        
        var icon: Image {
            switch self {
            case .stayInLoop:
                return .bellIcon
            case .privacy:
                return .settingsIconLock
            case .noFee:
                return .gasFeeIcon
            }
        }
    }
}

#Preview {
    ChatCreateMessagingProfileView()
}
