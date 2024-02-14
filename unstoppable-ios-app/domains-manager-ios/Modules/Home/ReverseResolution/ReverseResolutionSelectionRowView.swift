//
//  ReverseResolutionSelectionRowView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.01.2024.
//

import SwiftUI

struct ReverseResolutionSelectionRowView: View {
    
    @Environment(\.imageLoadingService) private var imageLoadingService

    let domain: DomainDisplayInfo
    let isSelected: Bool
    @State private var avatar: UIImage?
    
    var body: some View {
        UDListItemView(title: domain.name,
                       imageType: .uiImage(avatar ?? .init()),
                       imageStyle: .full,
                       rightViewStyle: isSelected ? .checkmark : .checkmarkEmpty)
        .onAppear(perform: onAppear)
    }
}

// MARK: - Private methods
private extension ReverseResolutionSelectionRowView {
    func onAppear() {
        Task {
            avatar = await imageLoadingService.loadImage(from: .domainInitials(domain, size: .default),
                                                         downsampleDescription: nil)
            if let avatar = await imageLoadingService.loadImage(from: .domain(domain),
                                                                downsampleDescription: .mid) {
                self.avatar = avatar
            }
        }
    }
}

#Preview {
    ReverseResolutionSelectionRowView(domain: .init(name: "oleg.x", ownerWallet: "123", isSetForRR: false),
                                      isSelected: false)
}
