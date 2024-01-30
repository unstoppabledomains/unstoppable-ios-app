//
//  HomeWalletExpandableSectionHeaderView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 30.01.2024.
//

import SwiftUI

struct HomeWalletExpandableSectionHeaderView: View {
    
    let title: String
    let isExpandable: Bool
    let numberOfItemsInSection: Int
    let isExpanded: Bool
    let actionCallback: EmptyCallback
    
    var body: some View {
        Button {
            UDVibration.buttonTap.vibrate()
            actionCallback()
        } label: {
            HStack {
                Text(title)
                    .font(.currentFont(size: 16, weight: .medium))
                    .foregroundStyle(Color.foregroundDefault)
                Spacer()
                
                if isExpandable {
                    HStack(spacing: 8) {
                        Text(String(numberOfItemsInSection))
                            .font(.currentFont(size: 16))
                        Image(uiImage: isExpanded ? .chevronUp : .chevronDown)
                            .resizable()
                            .squareFrame(20)
                    }
                    .foregroundStyle(Color.foregroundSecondary)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
