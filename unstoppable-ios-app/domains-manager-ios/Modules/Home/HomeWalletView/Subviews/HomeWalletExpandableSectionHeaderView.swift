//
//  HomeWalletExpandableSectionHeaderView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 30.01.2024.
//

import SwiftUI

struct HomeWalletExpandableSectionHeaderView: View {
    
    let title: String
    var titleValue: String? = nil
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
                HStack {
                    Text(title)
                        .foregroundStyle(Color.foregroundDefault)
                    if let titleValue {
                        Text(titleValue)
                            .foregroundStyle(Color.foregroundSecondary)
                    }
                }
                .font(.currentFont(size: 16, weight: .medium))
                .lineLimit(1)
                .truncationMode(.middle)
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
            .frame(height: 34)
        }
        .buttonStyle(.plain)
    }
}
