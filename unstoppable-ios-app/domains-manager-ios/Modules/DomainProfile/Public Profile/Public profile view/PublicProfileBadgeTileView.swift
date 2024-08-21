//
//  PublicProfileBadgeTileView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 11.03.2024.
//

import SwiftUI

struct PublicProfileBadgeTileView: View {
    
    @EnvironmentObject var viewModel: PublicProfileView.PublicProfileViewModel

    @StateObject private var badgeTitleViewModel: BadgeTitleViewModel
    let badge: DomainProfileBadgeDisplayInfo
    
    private var imagePadding: CGFloat { badge.badge.isUDBadge ? 8 : 4 }
    
    var body: some View {
        ZStack {
            Color.white
                .opacity(0.16)
            
            Image(uiImage: badgeTitleViewModel.icon ?? badge.defaultIcon)
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
        .id(badge.badge.code)
    }
    
    init(badge: DomainProfileBadgeDisplayInfo) {
        self.badge = badge
        self._badgeTitleViewModel = StateObject(wrappedValue: BadgeTitleViewModel(badge: badge))
    }
    
}

// MARK: - Private methods
private extension PublicProfileBadgeTileView {
    final class BadgeTitleViewModel: ObservableObject {
        @Published private(set) var icon: UIImage?
        
        let badge: DomainProfileBadgeDisplayInfo
        
        init(badge: DomainProfileBadgeDisplayInfo) {
            self.badge = badge
            loadImage()
        }
        
        func loadImage() {
            let badge = badge
            Task.detached { [weak self] in
                let icon = await badge.loadBadgeIcon()
                guard let self else { return }
                
                await MainActor.run {
                    self.icon = icon
                }
            }
        }
    }
}


#Preview {
    PublicProfileBadgeTileView(badge: DomainProfileBadgeDisplayInfo(badge: .exploreWeb3, isExploreWeb3Badge: true, icon: nil))
}
