//
//  AvatarStyleClipped.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 22.08.2023.
//

import SwiftUI

struct AvatarStyleClipped: ViewModifier {
    let avatarStyle: DomainAvatarImageView.AvatarStyle
    
    func body(content: Content) -> some View {
        switch avatarStyle {
        case .circle:
            content
                .clipShape(Circle())
        case .hexagon:
            content
                .clipShape(HexagonShape(rotation: .horizontal))
        }
    }
}

extension View {
    func clipForAvatarStyle(_ avatarStyle: DomainAvatarImageView.AvatarStyle) -> some View {
        modifier(AvatarStyleClipped(avatarStyle: avatarStyle))
    }
}
