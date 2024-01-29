//
//  HomeWalletNFTCellView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.01.2024.
//

import SwiftUI

struct HomeWalletNFTCellView: View {
    
    let nft: NFTDisplayInfo
    @State private var icon: UIImage?
    
    var body: some View {
        UIImageBridgeView(image: icon ?? .init(),
                          width: 20,
                          height: 20)
            .background(icon == nil ? Color.backgroundSubtle : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .aspectRatio(1, contentMode: .fit)
            .onChange(of: nft, perform: { newValue in
                loadIconFor(nft: newValue)
            })
            .onAppear(perform: onAppear)
    }
}

// MARK: - Private methods
private extension HomeWalletNFTCellView {
    func onAppear() {
        loadIconFor(nft: nft)
    }
    
    func loadIconFor(nft: NFTDisplayInfo) {
        icon = nil
        Task {
            let icon = await nft.loadIcon()
            self.icon = icon
        }
    }
}

#Preview {
    HomeWalletNFTCellView(nft: MockEntitiesFabric.NFTs.mockDisplayInfo())
}
