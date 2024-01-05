//
//  PreviewMessagingChatUserProfileDisplayInfo.swift
//  unstoppable-preview
//
//  Created by Oleg Kuplin on 04.01.2024.
//

import Foundation

extension MessagingChatUserProfileDisplayInfo {
    static func mock(serviceIdentifier: MessagingServiceIdentifier = .xmtp) -> MessagingChatUserProfileDisplayInfo {
        MessagingChatUserProfileDisplayInfo(id: "1",
                                            wallet: "",
                                            serviceIdentifier: serviceIdentifier)
    }
}
