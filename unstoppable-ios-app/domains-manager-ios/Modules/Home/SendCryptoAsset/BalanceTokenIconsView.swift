//
//  BalanceTokenIconsView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 20.03.2024.
//

import SwiftUI

struct BalanceTokenIconsView: View {
    
    let token: BalanceTokenUIDescription

    @State private var icon: UIImage?
    @State private var parentIcon: UIImage?
    
    var body: some View {
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
        .onChange(of: token, perform: { newValue in
            loadIconFor(token: newValue)
        })
    }
}

// MARK: - Private methods
private extension BalanceTokenIconsView {
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
    BalanceTokenIconsView(token: MockEntitiesFabric.Tokens.mockUIToken())
}
