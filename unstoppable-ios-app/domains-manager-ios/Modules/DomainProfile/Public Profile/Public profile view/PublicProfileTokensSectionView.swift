//
//  PublicProfileTokensSectionView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 04.03.2024.
//

import SwiftUI

struct PublicProfileTokensSectionView: View {
    
    @EnvironmentObject var viewModel: PublicProfileView.PublicProfileViewModel
    
    var body: some View {
        if let tokens = viewModel.tokens {
            LazyVStack(spacing: 20) {
                ForEach(tokens) { token in
                    Button {
                        
                    } label: {
                        HomeWalletTokenRowView(token: token)
                    }
                    .padding(EdgeInsets(top: -12, leading: 0, bottom: -12, trailing: 0))
                }
            }
        }
    }
}

#Preview {
    PublicProfileTokensSectionView()
}
