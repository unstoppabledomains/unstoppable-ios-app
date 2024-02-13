//
//  DomainSearchResultProfileRowView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 12.02.2024.
//

import SwiftUI

struct DomainSearchResultProfileRowView: View {
    
    
    @Environment(\.imageLoadingService) private var imageLoadingService
    
    let profile: SearchDomainProfile
    @State private var avatar: UIImage?
    
    var body: some View {
        UDListItemView(title: profile.name,
                       imageType: .uiImage(avatar ?? .init()),
                       imageStyle: .full,
                       rightViewStyle: .chevron)
        .onAppear(perform: onAppear)
    }
}

// MARK: - Private methods
private extension DomainSearchResultProfileRowView {
    func onAppear() {
        Task {
            avatar = await appContext.imageLoadingService.loadImage(from: .initials(profile.name,
                                                                                                 size: .default,
                                                                                                 style: .accent),
                                                                                 downsampleDescription: .icon)
            if let path = profile.imagePath,
               let image = await appContext.imageLoadingService.loadImage(from: .domainPFPSource(.nonNFT(imagePath: path)),
                                                                          downsampleDescription: .icon) {
                avatar = image
            }
        }
    }
}
