//
//  WalletDetailsDomainItemView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 08.05.2024.
//

import SwiftUI

struct WalletDetailsDomainItemView: View {
    
    @Environment(\.imageLoadingService) var imageLoadingService
    @EnvironmentObject var tabRouter: HomeTabRouter

    let domain: DomainDisplayInfo
    let selectionCallback: EmptyCallback
    @State private var domainIcon: UIImage?
    
    var body: some View {
        UDCollectionListRowButton(content: {
            UDListItemView(title: domain.name,
                           imageType: .uiImage(domainIcon ?? .init()),
                           imageStyle: .full)
                .udListItemInCollectionButtonPadding()
        }, callback: {
            selectionCallback()
        })
        .padding(4)
        .onAppear(perform: onAppear)
    }
}

// MARK: - Private methods
private extension WalletDetailsDomainItemView {
    func onAppear() {
        loadDomainIcon()
    }
    
    func loadDomainIcon() {
        Task {
            domainIcon = await imageLoadingService.loadImage(from: .domainItemOrInitials(domain, size: .default), downsampleDescription: .mid)
        }
    }
}

#Preview {
    WalletDetailsDomainItemView(domain: MockEntitiesFabric.Domains.mockDomainDisplayInfo(),
                                selectionCallback: { })
}
