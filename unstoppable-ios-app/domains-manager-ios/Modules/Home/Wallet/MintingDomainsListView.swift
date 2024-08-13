//
//  MintingDomainsListView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 13.08.2024.
//

import SwiftUI

struct MintingDomainsListView: View {
    
    @Environment(\.walletsDataService) var walletsDataService
    @Environment(\.dismiss) var dismiss
    
    @State var domains: [DomainDisplayInfo]
    
    var body: some View {
        VStack {
            ScrollView {
                LazyVStack(spacing: 24) {
                    titleView()
                    domainsList()
                }
                .padding(.horizontal, 16)
            }
            .padding(.top, 36)

            doneButton()
        }
        .background(Color.backgroundDefault)
        .onReceive(walletsDataService.selectedWalletPublisher.receive(on: DispatchQueue.main)) { selectedWallet in
            if let selectedWallet {
                setMintingDomainsFrom(wallet: selectedWallet)
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Private methods
private extension MintingDomainsListView {
    func setMintingDomainsFrom(wallet: WalletEntity) {
        let mintingDomains = wallet.domains.filter { $0.isMinting }
        if mintingDomains.isEmpty {
            dismiss()
        } else {
            self.domains = mintingDomains
        }
    }
    
    @ViewBuilder
    func titleView() -> some View {
        Text(String.Constants.pluralMintingNDomains.localized(domains.count, domains.count))
            .textAttributes(color: .foregroundDefault, fontSize: 22, fontWeight: .bold)
    }
    
    @ViewBuilder
    func domainsList() -> some View {
        UDCollectionSectionBackgroundView {
            LazyVStack(alignment: .center, spacing: 4) {
                ForEach(domains) { domain in
                    domainRowView(domain)
                }
            }
        }
    }
    
    @ViewBuilder
    func domainRowView(_ domain: DomainDisplayInfo) -> some View {
        HStack(spacing: 16) {
            TLDCategory.categoryFor(tld: domain.name.getTldName() ?? "")
                .icon
                .resizable()
                .squareFrame(24)
                .foregroundStyle(Color.foregroundSecondary)
            
            Text(domain.name)
                .textAttributes(color: .foregroundDefault,
                                fontSize: 16,
                                fontWeight: .medium)
                .lineLimit(1)
            Spacer()
            ProgressView()
                .tint(Color.foregroundDefault)
        }
        .frame(height: 64)
        .padding(.horizontal, 16)
    }
    
    
    @ViewBuilder
    func doneButton() -> some View {
        UDButtonView(text: String.Constants.doneButtonTitle.localized(),
                     style: .large(.raisedPrimary)) {
            dismiss()
        }
    }
}

#Preview {
    MintingDomainsListView(domains: MockEntitiesFabric.Domains.mockDomainsDisplayInfo(ownerWallet: "1"))
}
