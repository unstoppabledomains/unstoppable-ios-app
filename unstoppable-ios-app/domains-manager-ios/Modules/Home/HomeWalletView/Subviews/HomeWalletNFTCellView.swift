//
//  HomeWalletNFTCellView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.01.2024.
//

import SwiftUI

struct HomeWalletNFTCellView: View {
    
    @State var nft: NFTDisplayInfo
    @State private var icon: UIImage?
    
    var body: some View {
        UIImageBridgeView(image: icon ?? .init(),
                          width: 20,
                          height: 20)
            .background(icon == nil ? Color.backgroundSubtle : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .aspectRatio(1, contentMode: .fit)
            .onAppear(perform: onAppear)
    }
}

// MARK: - Private methods
private extension HomeWalletNFTCellView {
    func onAppear() {
        if icon == nil {
            Task {
                icon = await nft.loadIcon()
            }
        }
    }
}

#Preview {
    HomeWalletNFTCellView(nft: .mock())
}
