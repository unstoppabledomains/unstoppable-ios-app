//
//  HomeWalletDomainCellView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.01.2024.
//

import SwiftUI

struct HomeWalletDomainCellView: View {
    
    @Environment(\.imageLoadingService) private var imageLoadingService

    let domain: DomainDisplayInfo
    @State private var icon: UIImage?

    var body: some View {
        viewForCurrentDomain()
        .onAppear(perform: onAppear)
        .onChange(of: domain, perform: { _ in
            loadAvatar()
        })
    }
}

// MARK: - Private methods
private extension HomeWalletDomainCellView {
    func onAppear() {
        loadAvatar()
    }
    
    func loadAvatar() {
        Task {
            icon = await imageLoadingService.loadImage(from: .domain(domain), downsampleDescription: .mid)
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
            VStack(alignment: .leading) {
                cartLogoView()
                Spacer()
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(domain.name.getBelowTld() ?? "")
                            .frame(height: 24)
                        Text("." + tldName)
                            .offset(x: -4)
                            .frame(height: 20)
                    }
                    .font(.currentFont(size: 20, weight: .medium))
                    domainStatusView()
                }
            }
            .foregroundStyle(Color.white)
            .padding(EdgeInsets(top: 4, leading: 8, bottom: 8, trailing: 4))
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    @ViewBuilder
    func domainStatusView() -> some View {
        if let indicator = resolveIndicatorStyle() {
            CarouselViewBridgeView(data: [indicator],
                                   backgroundColor: indicator.containerBackgroundColor,
                                   sideGradientHidden: true)
                .frame(height: 24)
                .padding(EdgeInsets(top: 4, leading: -8, bottom: -8, trailing: -4))
        }
    }
    
    func resolveIndicatorStyle() -> DomainIndicatorStyle? {
        switch domain.state {
        case .default:
            switch domain.usageType {
            case .normal, .newNonInteractable, .parked:
                return nil
            case .deprecated(let tld):
                return .deprecated(tld: tld)
            }
        case .updatingRecords, .updatingReverseResolution:
            return .updatingRecords
        case .minting:
            return .minting
        case .parking(let status):
            return .parked(status: status)
        case .transfer:
            return .transfer
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
            Color.white
            Image.subdomainGridBackground
            cartLogoView()
                .foregroundStyle(Color.black)
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
        UIImageBridgeView(image: icon ?? .domainSharePlaceholder)
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

// MARK: - Private methods
private extension HomeWalletDomainCellView {
    enum DomainIndicatorStyle: CarouselViewItem {
        case updatingRecords, minting, deprecated(tld: String), parked(status: DomainParkingStatus), transfer
        
        var isRotating: Bool {
            switch self {
            case .updatingRecords, .minting, .transfer:
                return true
            default:
                return false
            }
        }
        
        var containerBackgroundColor: UIColor {
            switch self {
            case .updatingRecords, .minting:
                return .brandElectricYellow
            case .transfer:
                return .brandElectricGreen
            case .deprecated, .parked:
                return .brandOrange
            }
        }
        
        /// CarouselViewItem properties
        var icon: UIImage {
            switch self {
            case .updatingRecords, .minting, .transfer:
                return .refreshIcon
            case .deprecated:
                return .warningIconLarge
            case .parked:
                return .parkingIcon24
            }
        }
        
        var text: String {
            switch self {
            case .updatingRecords:
                return String.Constants.updatingRecords.localized()
            case .minting:
                return String.Constants.mintingDomain.localized()
            case .deprecated(let tld):
                return String.Constants.tldHasBeenDeprecated.localized(tld)
            case .parked(let status):
                return status.title ?? String.Constants.parked.localized()
            case .transfer:
                return String.Constants.transferInProgress.localized()
            }
        }
        
        var tintColor: UIColor {
            switch self {
            case .updatingRecords, .minting, .deprecated, .parked, .transfer:
                return .black
            }
        }
        
        var backgroundColor: UIColor {
            switch self {
            case .updatingRecords, .minting, .deprecated, .parked, .transfer:
                return .clear
            }
        }
    }
}

#Preview {
    HomeWalletDomainCellView(domain: .init(name: "sub.oleg.x", ownerWallet: "", isSetForRR: false))
        .frame(width: 200, height: 200)
}
