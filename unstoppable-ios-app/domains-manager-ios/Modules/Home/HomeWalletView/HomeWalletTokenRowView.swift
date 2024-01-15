//
//  HomeWalletTokenRowView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 15.01.2024.
//

import SwiftUI

struct HomeWalletTokenRowView: View {
    
    let token: HomeWalletView.TokenDescription
    let onAppear: EmptyCallback
    
    var body: some View {
        HStack(spacing: 16) {
            Image(uiImage: token.icon ?? .ethBGLarge)
                .resizable()
                .squareFrame(40)
                .clipShape(Circle())
            
            VStack(alignment: .leading) {
                Text(token.name)
                    .font(.currentFont(size: 16, weight: .medium))
                    .foregroundStyle(Color.foregroundDefault)
                Text("\(Int(token.balance)) \(token.symbol)")
                    .font(.currentFont(size: 14, weight: .regular))
                    .foregroundStyle(Color.foregroundSecondary)
            }
            Spacer()
            
            VStack(alignment: .leading) {
                if let fiatValue = token.fiatValue {
                    Text("$\(Int(fiatValue))")
                        .font(.currentFont(size: 16, weight: .medium))
                        .foregroundStyle(Color.foregroundDefault)
                }
            }
        }
        .frame(height: 64)
        .onAppear {
            onAppear()
        }
    }
}

#Preview {
    HomeWalletTokenRowView(token: HomeWalletView.TokenDescription.mock().first!,
                           onAppear: { })
}
