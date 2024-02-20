//
//  Chat.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 19.09.2023.
//

import UIKit

// Namespace
enum Chat { }

extension Chat {
    enum ChatLinkHandleAction: CaseIterable, PullUpCollectionViewCellItem {
       
        case handle
        case block
        
        var title: String {
            switch self {
            case .handle:
                return "Open"
            case .block:
                return "Cancel & block"
            }
        }
        
        var icon: UIImage {
            switch self {
            case .handle:
                return .safari
            case .block:
                return .systemMinusCircle
            }
        }
        
        var analyticsName: String {
            switch self {
            case .handle:
                return "handle"
            case .block:
                return "block"
            }
        }
        
    }
}

extension Chat {
    enum ChatMessageAction: Hashable {
        case resend
        case delete
        case unencrypted
        case viewSenderProfile(MessagingChatSender)
        
        case copyText(String)
        case sendReaction(content: String, toMessage: String)
        case saveImage(UIImage)
        case blockUserInGroup(MessagingChatUserDisplayInfo)
    }
}
