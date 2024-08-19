//
//  PurchaseSearchEmptyView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.08.2024.
//

import SwiftUI

struct PurchaseSearchEmptyView: View {
    
    let mode: PurchaseDomains.EmptyStateMode
    
    var body: some View {
        VStack(spacing: 16) {
            mode.icon
                .resizable()
                .squareFrame(48)
            Text(mode.title)
                .font(.currentFont(size: 22, weight: .bold))
            if let subtitle = mode.subtitle {
                Text(subtitle)
                    .font(.currentFont(size: 14))
            }
        }
        .foregroundStyle(Color.foregroundSecondary)
        .padding(.horizontal, 16)
        .backgroundStyle(Color.clear)
        .padding(.top, 56)
    }
}

#Preview {
    PurchaseSearchEmptyView(mode: .start)
}
