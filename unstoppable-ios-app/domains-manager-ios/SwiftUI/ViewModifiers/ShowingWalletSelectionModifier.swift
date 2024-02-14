//
//  ShowingWalletSelectionModifier.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 12.02.2024.
//

import SwiftUI

struct ShowingWalletSelectionModifier: ViewModifier {
    @Binding var isSelectWalletPresented: Bool
    
    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isSelectWalletPresented, content: {
                UserProfileSelectionView()
                    .adaptiveSheet()
            })
    }
}
