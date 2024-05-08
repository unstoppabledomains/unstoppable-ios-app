//
//  WalletDetailsDomainItemView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 08.05.2024.
//

import SwiftUI

struct WalletDetailsDomainItemView: View {
    
    @Environment(\.imageLoadingService) var imageLoadingService
    
    let domain: DomainDisplayInfo
    @State private var domainIcon: UIImage?
    
    var body: some View {
        UDListItemView(title: domain.name,
                       imageType: .uiImage(domainIcon ?? .init()),
                       imageStyle: .full)
            .onAppear(perform: onAppear)
    }
}

// MARK: - Private methods
private extension WalletDetailsDomainItemView {
    func onAppear() {
        print("Appear \(domain.name)")
        loadDomainIcon()
    }
    
    func loadDomainIcon() {
        Task {
            domainIcon = await imageLoadingService.loadImage(from: .domainItemOrInitials(domain, size: .default), downsampleDescription: .mid)
        }
    }
}

#Preview {
    WalletDetailsDomainItemView(domain: MockEntitiesFabric.Domains.mockDomainDisplayInfo())
}
