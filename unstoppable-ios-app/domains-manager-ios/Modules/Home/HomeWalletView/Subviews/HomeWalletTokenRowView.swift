//
//  HomeWalletTokenRowView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 15.01.2024.
//

import SwiftUI

struct HomeWalletTokenRowView: View {
    
    static let height: CGFloat = 64
    let token: BalanceTokenUIDescription
    var secondaryColor: Color = .foregroundSecondary
    @State private var icon: UIImage?
    @State private var parentIcon: UIImage?
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack(alignment: .bottomTrailing) {
                Image(uiImage: icon ?? .init())
                    .resizable()
                    .squareFrame(40)
                    .background(Color.backgroundSubtle)
                    .skeletonable()
                    .clipShape(Circle())
                
                if token.parentSymbol != nil {
                    Image(uiImage: parentIcon ?? .init())
                        .resizable()
                        .squareFrame(20)
                        .background(Color.backgroundDefault)
                        .skeletonable()
                        .clipShape(Circle())
                        .overlay {
                            Circle()
                                .stroke(lineWidth: 2)
                                .foregroundStyle(Color.backgroundDefault)
                        }
                        .offset(x: 4, y: 4)
                }
            }
            
            VStack(alignment: .leading,
                   spacing: token.isSkeleton ? 8 : 0) {
                Text(token.name)
                    .font(.currentFont(size: 16, weight: .medium))
                    .foregroundStyle(Color.foregroundDefault)
                    .frame(height: token.isSkeleton ? 16 : 24)
                    .skeletonable()
                    .skeletonCornerRadius(12)
                Text("\(token.balance.formatted(toMaxNumberAfterComa: 2)) \(token.symbol)")
                    .font(.currentFont(size: 14, weight: .regular))
                    .foregroundStyle(secondaryColor)
                    .frame(height: token.isSkeleton ? 12 : 20)
                    .skeletonable()
                    .skeletonCornerRadius(10)
            }
            Spacer()
            
            VStack(alignment: .trailing,
                   spacing: 0) {
                Text("$\(token.balanceUsd.formatted(toMaxNumberAfterComa: 2))")
                    .font(.currentFont(size: 16, weight: .medium))
                    .monospacedDigit()
                    .foregroundStyle(Color.foregroundDefault)
                    .skeletonable()
                    .skeletonCornerRadius(12)
                if let pctChange = token.marketPctChange24Hr {
                    Text("\(pctChange.formatted(toMaxNumberAfterComa: 2))%")
                        .font(.currentFont(size: 14))
                        .foregroundStyle(pctChange > 0 ? Color.foregroundSuccess : secondaryColor)
                        .frame(height: token.isSkeleton ? 12 : 20)
                        .skeletonable()
                        .skeletonCornerRadius(10)
                }
            }
        }
        .frame(height: HomeWalletTokenRowView.height)
        .onChange(of: token, perform: { newValue in
            loadIconFor(token: newValue)
        })
        .onAppear {
            onAppear()
        }
        .setSkeleton(.constant(token.isSkeleton),
                     animationType: .solid(.backgroundSubtle))
    }
}

// MARK: - Private methods
private extension HomeWalletTokenRowView {
    func onAppear() {
        loadIconFor(token: token)
    }
    
    func loadIconFor(token: BalanceTokenUIDescription) {
        guard !token.isSkeleton else {
            icon = nil
            parentIcon = nil
            return }
        
        token.loadTokenIcon { image in
            self.icon = image
        }
        token.loadParentIcon { image in
            self.parentIcon = image
        }
    }
}

#Preview {
    HomeWalletTokenRowView(token: .init(chain: "ETH",
                                        symbol: "ETH",
                                        name: "ETH",
                                        balance: 1,
                                        balanceUsd: 1,
                                        marketUsd: 1))
}
