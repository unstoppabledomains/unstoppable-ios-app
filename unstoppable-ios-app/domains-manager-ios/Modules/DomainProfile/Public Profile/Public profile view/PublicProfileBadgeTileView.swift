//
//  PublicProfileBadgeTileView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 11.03.2024.
//

import SwiftUI

struct PublicProfileBadgeTileView: View {
    
    @EnvironmentObject var viewModel: PublicProfileView.PublicProfileViewModel

    let badge: DomainProfileBadgeDisplayInfo
    
    private var imagePadding: CGFloat { badge.badge.isUDBadge ? 8 : 4 }
    @State private var icon: UIImage?
    
    var body: some View {
        ZStack {
            Color.white
                .opacity(0.16)
            
            Image(uiImage: icon ?? badge.defaultIcon)
                .resizable()
                .aspectRatio(1, contentMode: .fit)
                .scaledToFill()
                .clipped()
                .clipShape(Circle())
                .foregroundColor(.white)
                .padding(imagePadding)
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(Circle())
        .onAppear {
            Task {
                icon = await badge.loadBadgeIcon()
            }
        }
    }
    
}

#Preview {
    PublicProfileBadgeTileView(badge: DomainProfileBadgeDisplayInfo(badge: .exploreWeb3, isExploreWeb3Badge: true, icon: nil))
}
