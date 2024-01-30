//
//  HomeWalletDomainCellView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.01.2024.
//

import SwiftUI

struct HomeWalletDomainCellView: View {
    
    @Environment(\.imageLoadingService) private var imageLoadingService

    @State var domain: DomainDisplayInfo
    @State private var icon: UIImage?

    var body: some View {
        viewForCurrentDomain()
        .onAppear(perform: onAppear)
    }
}

// MARK: - Private methods
private extension HomeWalletDomainCellView {
    func onAppear() {
        if icon == nil {
            Task {
                icon = await imageLoadingService.loadImage(from: .domain(domain), downsampleDescription: .mid)
            }
        }
    }
    
    var tldName: String { domain.name.getTldName() ?? "" }
    
    @ViewBuilder
    func viewForCurrentDomain() -> some View {
        if domain.isSubdomain {
            viewForSubdomain()
        } else {
            viewForDomain()
        }
    }
    
    @ViewBuilder
    func viewForDomain() -> some View {
        ZStack(alignment: .leading) {
            domainAvatarView(cornerRadius: 12)
            VStack {
                cartLogoView()
                    .offset(x: -12)
                Spacer()
                VStack(alignment: .leading, spacing: 0) {
                    Text(domain.name.getBelowTld() ?? "")
                    Text("." + tldName)
                        .offset(x: -4)
                }
                .font(.currentFont(size: 20, weight: .medium))
            }
            .foregroundStyle(Color.white)
            .padding(EdgeInsets(top: 4, leading: 8, bottom: 8, trailing: 4))
        }
    }
    
    var subdomainComponents: [String] {
        let maxToShow = 2
        let components = domain.name.getComponentsBelowTld() ?? []
        return Array(components.prefix(maxToShow))
    }
    
    @ViewBuilder
    func viewForSubdomain() -> some View {
        ZStack(alignment: .topLeading) {
            Color(hex: "#EDEDEE")
            cartLogoView().foregroundStyle(Color.black)
                .padding(EdgeInsets(top: 8, leading: 8, bottom: 0, trailing: 0))
            subdomainMiddleTile()
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .aspectRatio(1, contentMode: .fit)
    }
    
    @ViewBuilder
    func subdomainMiddleTile() -> some View {
        VStack {
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .foregroundStyle(Color.black)
                    .frame(height: 60)
                HStack(alignment: .top, spacing: 6) {
                    domainAvatarView(cornerRadius: 8)
                        .squareFrame(32)
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(subdomainComponents, id: \.self) { component in
                            subdomainComponentText(component, isPrimary: component == subdomainComponents.first)
                        }
                        subdomainComponentText(tldName, isPrimary: false)
                    }
                    .foregroundStyle(Color.white)
                    Spacer()
                }
                .padding(EdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6))
            }
            .shadow(color: .black.opacity(0.16), radius: 1.12418, x: 0, y: 0.89935)
            .shadow(color: .black.opacity(0.32), radius: 8.99346, x: 0, y: 6.29542)
            Spacer()
        }
        .sideInsets(8)
    }
    
    @ViewBuilder
    func subdomainComponentText(_ name: String, isPrimary: Bool) -> some View {
        Text(isPrimary ? name : ".\(name)")
            .font(.currentFont(size: isPrimary ? 18 : 13))
            .frame(height: isPrimary ? 18 : 13)
            .offset(x: isPrimary ? 0 : -2)
    }
    
    @ViewBuilder
    func cartLogoView() -> some View {
        Image.udCartLogoRaster
            .resizable()
            .renderingMode(.template)
            .squareFrame(40)
    }
    
    @ViewBuilder
    func domainAvatarView(cornerRadius: CGFloat) -> some View {
        UIImageBridgeView(image: icon ?? .domainSharePlaceholder,
                          width: 20,
                          height: 20)
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

#Preview {
    HomeWalletDomainCellView(domain: .init(name: "sub.oleg.x", ownerWallet: "", isSetForRR: false))
        .frame(width: 200, height: 200)
}
