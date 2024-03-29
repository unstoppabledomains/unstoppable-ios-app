//
//  MessagingServiceIdentifier.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 02.10.2023.
//

import Foundation

enum MessagingServiceIdentifier: String, Hashable, CaseIterable {
    case xmtp = "xmtp"
    case push = "push"
}
