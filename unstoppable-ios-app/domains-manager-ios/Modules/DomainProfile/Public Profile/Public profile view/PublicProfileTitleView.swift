//
//  PublicProfileTitleView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 09.03.2024.
//

import SwiftUI

struct PublicProfileTitleView: View {
    
    @Environment(\.imageLoadingService) var imageLoadingService
    @EnvironmentObject var viewModel: PublicProfileView.PublicProfileViewModel
    
    @State private var avatar: UIImage?
    
    var body: some View {
        HStack(spacing: 8) {
            titleIconView()
            titleView()
        }
        .onAppear(perform: onAppear)
    }
    
}

// MARK: - Private methods
private extension PublicProfileTitleView {
    func onAppear() {
        loadAvatar()
    }
    
    func loadAvatar() {
        if let avatarImage = viewModel.avatarImage {
            self.avatar = avatarImage
        }
    }
    
    @ViewBuilder
    func titleView() -> some View {
        Text(viewModel.domain.name)
            .font(.currentFont(size: 16, weight: .semibold))
            .foregroundStyle(.white)
            .lineLimit(1)
    }
    
    @ViewBuilder
    func titleIconView() -> some View {
        UIImageBridgeView(image: avatar ?? .domainSharePlaceholder)
            .squareFrame(20)
            .clipShape(Circle())
    }
}

#Preview {
    PublicProfileTitleView()
}
