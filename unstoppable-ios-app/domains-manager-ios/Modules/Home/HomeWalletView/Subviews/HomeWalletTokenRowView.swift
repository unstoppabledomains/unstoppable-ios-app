//
//  HomeWalletTokenRowView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 15.01.2024.
//

import SwiftUI

struct HomeWalletTokenRowView: View {
    
    static let height: CGFloat = 64
    let token: HomeWalletView.TokenDescription
    let onAppear: EmptyCallback
    
    var body: some View {
        HStack(spacing: 16) {
            Image(uiImage: token.icon ?? .init())
                .resizable()
                .squareFrame(40)
                .background(Color.backgroundSubtle)
                .skeletonable()
                .clipShape(Circle())
            
            VStack(alignment: .leading,
                   spacing: token.isSkeleton ? 8 : 0) {
                Text(token.name)
                    .font(.currentFont(size: 16, weight: .medium))
                    .foregroundStyle(Color.foregroundDefault)
                    .frame(height: token.isSkeleton ? 16 : 24)
                    .skeletonable()
                    .skeletonCornerRadius(12)
                Text("\(Int(token.balance)) \(token.symbol)")
                    .font(.currentFont(size: 14, weight: .regular))
                    .foregroundStyle(Color.foregroundSecondary)
                    .frame(height: token.isSkeleton ? 12 : 20)
                    .skeletonable()
                    .skeletonCornerRadius(10)
            }
            Spacer()
            
            VStack(alignment: .leading) {
                if let fiatValue = token.fiatValue {
                    Text("$\(Int(fiatValue))")
                        .font(.currentFont(size: 16, weight: .medium))
                        .foregroundStyle(Color.foregroundDefault)
                        .skeletonable()
                        .skeletonCornerRadius(12)
                }
            }
        }
        .frame(height: HomeWalletTokenRowView.height)
        .onAppear {
            onAppear()
        }
        .setSkeleton(.constant(token.isSkeleton),
                     animationType: .solid(.backgroundSubtle))
    }
}

#Preview {
    HomeWalletTokenRowView(token: HomeWalletView.TokenDescription.mock().first!,
                           onAppear: { })
}
