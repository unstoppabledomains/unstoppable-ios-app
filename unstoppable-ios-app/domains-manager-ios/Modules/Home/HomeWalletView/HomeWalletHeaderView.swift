//
//  HomeWalletHeaderView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 15.01.2024.
//

import SwiftUI

struct HomeWalletHeaderView: View {
    
    let wallet: WalletWithInfo
    let totalBalance: Int
    let domainNamePressedCallback: EmptyCallback
    
    var body: some View {
        VStack(alignment: .center, spacing: 20) {
            Image(uiImage: UIImage.Preview.previewPortrait!)
                .resizable()
                .squareFrame(80)
                .clipShape(Circle())
                .background(Color.clear)
                .shadow(color: Color.backgroundDefault, radius: 24, x: 0, y: 0)
                .overlay {
                    Circle()
                        .stroke(lineWidth: 2)
                        .foregroundStyle(Color.backgroundDefault)
                }
            
            Button {
                domainNamePressedCallback()
            } label: {
                HStack {
                    Text(getCurrentTitle())
                        .font(.currentFont(size: 16, weight: .medium))
                    
                    Image(systemName: "chevron.up.chevron.down")
                        .squareFrame(20)
                }
                .foregroundStyle(Color.foregroundSecondary)
            }
            .buttonStyle(.plain)
            
            Text(formatCartPrice(totalBalance))
                .titleText()
        }
        .frame(maxWidth: .infinity)
    }
    
}

// MARK: - Private methods
private extension HomeWalletHeaderView {
    func getCurrentTitle() -> String {
        if let rrDomain = wallet.displayInfo?.reverseResolutionDomain {
            return rrDomain.name
        }
        return wallet.address.walletAddressTruncated
    }
}

#Preview {
    HomeWalletHeaderView(wallet: WalletWithInfo.mock.first!,
                         totalBalance: 20000,
                         domainNamePressedCallback: { })
}
