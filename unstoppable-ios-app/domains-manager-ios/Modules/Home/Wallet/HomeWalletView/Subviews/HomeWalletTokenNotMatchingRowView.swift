//
//  HomeWalletTokenNotMatchingRowView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 30.01.2024.
//

import SwiftUI

struct HomeWalletTokenNotMatchingRowView: View {
    
    let description: HomeWalletView.NotMatchedRecordsDescription
    @State private var icon: UIImage?

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Image(uiImage: icon ?? .init())
                    .resizable()
                    .squareFrame(40)
                    .background(Color.backgroundSubtle)
                    .clipShape(Circle())
                Circle()
                    .foregroundStyle(Color.black.opacity(0.4))
                    .squareFrame(40)
            }
            
            HStack(spacing: 0) {
                VStack(alignment: .leading,
                       spacing: 0) {
                    Text(title)
                        .font(.currentFont(size: 16, weight: .medium))
                        .foregroundStyle(Color.foregroundDefault)
                        .frame(height: 24)
                    Text(String.Constants.recordsDoesNotMatchOwnersAddress.localized())
                        .font(.currentFont(size: 14, weight: .medium))
                        .foregroundStyle(Color.foregroundWarning)
                        .frame(height: 20)
                }
                Spacer()
                Image(systemName: "info.circle")
                    .resizable()
                    .squareFrame(20)
                    .foregroundStyle(Color.foregroundSecondary)
            }
        }
        .frame(height: HomeWalletTokenRowView.height)
        .onChange(of: description, perform: { newValue in
            loadIconFor(description: newValue)
        })
        .onAppear {
            onAppear()
        }
    }
}

// MARK: - Private methods
private extension HomeWalletTokenNotMatchingRowView {
    func onAppear() {
        loadIconFor(description: description)
    }
    
    func loadIconFor(description: HomeWalletView.NotMatchedRecordsDescription) {
        icon = nil
       
        BalanceTokenUIDescription.loadIconFor(ticker: description.chain.rawValue, logoURL: nil) { image in
            DispatchQueue.main.async {
                self.icon = image
            }
        }
    }
    
    var title: String {
        let fullName = description.chain.fullName
        if description.numberOfRecordsNotSetToChain > 1 {
            return "\(fullName) (\(description.numberOfRecordsNotSetToChain))"
        }
        return fullName
    }
}

#Preview {
    HomeWalletTokenNotMatchingRowView(description: .init(chain: .Ethereum,
                                                         numberOfRecordsNotSetToChain: 1,
                                                         ownerWallet: "123"))
    .frame(width: 390, height: 64)
    
}
