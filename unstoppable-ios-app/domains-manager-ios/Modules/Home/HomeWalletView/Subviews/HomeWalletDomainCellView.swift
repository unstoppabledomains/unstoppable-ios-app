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
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    @ViewBuilder
    func domainStatusView() -> some View {
        if let indicator = resolveIndicatorStyle() {
            CarouselViewBridgeView(style: .transfer, sideGradientHidden: true)
                .frame(height: 24)
                .padding(EdgeInsets(top: 4, leading: -8, bottom: -8, trailing: -4))
        }
    }
    
    func resolveIndicatorStyle() -> CarouselViewBridgeView.DomainIndicatorStyle? {
        switch domain.state {
        case .default:
            switch domain.usageType {
            case .normal, .newNonInteractable, .parked:
                return nil
            case .deprecated(let tld):
                return .deprecated(tld: tld)
            case .zil:
                return .deprecated(tld: "zil")
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
            GridView(rows: 10,
                     cols: 10,
                     gridColor: LinearGradient(
                stops: [
                    Gradient.Stop(color: .black.opacity(0), location: 0.00),
                    Gradient.Stop(color: .black.opacity(0.08), location: 0.14),
                    Gradient.Stop(color: .black.opacity(0.08), location: 0.86),
                    Gradient.Stop(color: .black.opacity(0), location: 1.00),
                ],
                startPoint: UnitPoint(x: 0, y: 0.08),
                endPoint: UnitPoint(x: 1, y: 0.08)
            ), lineWidth: 0.2)
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
        UIImageBridgeView(image: icon ?? .domainSharePlaceholder,
                          width: 20,
                          height: 20)
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
    
    struct GridView<S : ShapeStyle>: View {
        
        let rows: CGFloat
        let cols: CGFloat
        let gridColor: S
        let lineWidth: CGFloat
        
        var body: some View {
            
            GeometryReader { geometry in
                
                let width = geometry.size.width
                let height = geometry.size.height
                let xSpacing = width / cols
                let ySpacing = height / rows
                
                Path { path in
                    for index in 0...Int(cols) {
                        let vOffset: CGFloat = CGFloat(index) * xSpacing
                        path.move(to: CGPoint(x: vOffset, y: 0))
                        path.addLine(to: CGPoint(x: vOffset, y: height))
                    }
                    for index in 0...Int(rows) {
                        let hOffset: CGFloat = CGFloat(index) * ySpacing
                        path.move(to: CGPoint(x: 0, y: hOffset))
                        path.addLine(to: CGPoint(x: width, y: hOffset))
                    }
                }
                .stroke(gridColor, lineWidth: lineWidth)
            }
        }
    }

}

#Preview {
    HomeWalletDomainCellView(domain: .init(name: "sub.oleg.x", ownerWallet: "", isSetForRR: false))
        .frame(width: 200, height: 200)
}
