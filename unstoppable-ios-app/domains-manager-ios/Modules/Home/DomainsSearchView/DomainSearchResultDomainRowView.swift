//
//  DomainSearchResultRowView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 12.02.2024.
//

import SwiftUI

struct DomainSearchResultDomainRowView: View {
    
    @Environment(\.imageLoadingService) private var imageLoadingService

    let domain: DomainDisplayInfo
    @State private var avatar: UIImage?

    var body: some View {
        UDListItemView(title: domain.name,
                       imageType: .uiImage(avatar ?? .init()),
                       imageStyle: .full,
                       rightViewStyle: .chevron)
        .onAppear(perform: onAppear)
    }
}

// MARK: - Private methods
private extension DomainSearchResultDomainRowView {
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
