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
        ZStack(alignment: .leading) {
            UIImageBridgeView(image: icon ?? .domainSharePlaceholder,
                              width: 20,
                              height: 20)
            .aspectRatio(1, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            VStack {
                Image.udCartLogoRaster
                    .resizable()
                    .squareFrame(40)
                    .offset(x: -12)
                Spacer()
                VStack(alignment: .leading, spacing: 0) {
                    Text(domain.name.getBelowTld() ?? "")
                    Text("." + (domain.name.getTldName() ?? ""))
                        .offset(x: -4)
                }
                .font(.currentFont(size: 20, weight: .medium))
            }
            .foregroundStyle(Color.white)
            .padding(EdgeInsets(top: 4, leading: 8, bottom: 8, trailing: 4))
        }
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
}

#Preview {
    HomeWalletDomainCellView(domain: .init(name: "oleg.x", ownerWallet: "", isSetForRR: false))
}
