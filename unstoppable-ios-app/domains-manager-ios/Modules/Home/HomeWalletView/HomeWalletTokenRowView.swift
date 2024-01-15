//
//  HomeWalletTokenRowView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 15.01.2024.
//

import SwiftUI

struct HomeWalletTokenRowView: View {
    
    let token: TokenDescription
    
    var body: some View {
        HStack(spacing: 16) {
            Image(uiImage: .ethBGLarge)
                .resizable()
                .squareFrame(40)
                .clipShape(Circle())
            
            VStack(alignment: .leading) {
                Text(token.fullName)
                    .font(.currentFont(size: 16, weight: .medium))
                    .foregroundStyle(Color.foregroundDefault)
                Text("\(Int(token.value)) \(token.ticker)")
                    .font(.currentFont(size: 14, weight: .regular))
                    .foregroundStyle(Color.foregroundSecondary)
            }
            Spacer()
            
            VStack(alignment: .leading) {
                Text("$\(Int(token.fiatValue))")
                    .font(.currentFont(size: 16, weight: .medium))
                    .foregroundStyle(Color.foregroundDefault)
            }
        }
        .frame(height: 64)
    }
}

#Preview {
    HomeWalletTokenRowView(token: TokenDescription.mock().first!)
}
