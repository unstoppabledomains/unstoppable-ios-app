//
//  WalletDetailsDomainItemView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 08.05.2024.
//

import SwiftUI

struct WalletDetailsDomainItemView: View {
    
    @Environment(\.imageLoadingService) var imageLoadingService
    @Environment(\.walletsDataService) var walletsDataService
    @EnvironmentObject var tabRouter: HomeTabRouter

    let domain: DomainDisplayInfo
    let canSetRR: Bool
    let selectionCallback: EmptyCallback
    @State private var domainIcon: UIImage?
    
    var body: some View {
        UDCollectionListRowButton(content: {
            UDListItemView(title: domain.name,
                           subtitle: getSubtitle(),
                           subtitleIcon: getSubtitleIcon(),
                           imageType: .uiImage(domainIcon ?? .init()),
                           imageStyle: .full,
                           rightViewStyle: getRightViewStyle())
                .udListItemInCollectionButtonPadding()
        }, callback: {
            selectionCallback()
        })
        .onChange(of: domain, perform: { newValue in
            domainIcon = nil
            loadDomainIcon(domain: newValue)
        })
        .padding(4)
        .onAppear(perform: onAppear)
    }
}

// MARK: - Private methods
private extension WalletDetailsDomainItemView {
    func onAppear() {
        loadDomainIcon(domain: domain)
    }
    
    func loadDomainIcon(domain: DomainDisplayInfo) {
        Task {
            domainIcon = await imageLoadingService.loadImage(from: .domainItemOrInitials(domain, size: .default), downsampleDescription: .mid)
        }
    }
    
    func getSubtitle() -> String? {
        domain.isSetForRR ? String.Constants.primary.localized() : nil
    }
    
    func getSubtitleIcon() -> UDListItemView.ImageType? {
        domain.isSetForRR ? .image(.crownIcon) : nil
    }
    
    func getRightViewStyle() -> UDListItemView.RightViewStyle {
        .generic(.init(type: .menu(primary: .init(icon: .dotsCircleIcon,
                                                  callback: {
            
        }), actions: getActions()),
                       tintColor: .foregroundDefault))
    }
    
    func getActions() -> [UDListItemView.RightViewStyle.GenericSubActionDetails] {
        var actions: [UDListItemView.RightViewStyle.GenericSubActionDetails] = [.init(title: String.Constants.copyDomain.localized(),
                                                                                      iconName: "doc.on.doc",
                                                                                      callback: copyDomainName)]
        
        if canSetRR,
           domain.isAbleToSetAsRR,
           !domain.isSetForRR {
            actions.append(.init(title: String.Constants.setAsPrimaryDomain.localized(),
                                 iconName: "crown",
                                 callback: setAsRR))
        }
        
        return actions
    }
    
    func copyDomainName() {
        UIPasteboard.general.string = domain.name
        appContext.toastMessageService.showToast(.domainCopied, isSticky: false)
    }
    
    func setAsRR() {
        guard let wallet = walletsDataService.wallets.findOwningDomain(domain.name) else { return }
        
        tabRouter.resolvingPrimaryDomainWallet = .init(wallet: wallet,
                                                       mode: .certain(domain))
    }
}

#Preview {
    WalletDetailsDomainItemView(domain: MockEntitiesFabric.Domains.mockDomainDisplayInfo(),
                                canSetRR: true,
                                selectionCallback: { })
}
