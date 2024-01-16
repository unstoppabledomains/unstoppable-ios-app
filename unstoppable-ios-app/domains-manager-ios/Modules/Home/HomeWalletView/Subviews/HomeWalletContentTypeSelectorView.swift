//
//  HomeWalletContentTypeSelectorView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 15.01.2024.
//

import SwiftUI

struct HomeWalletContentTypeSelectorView: View {
    
    @Binding var selectedContentType: HomeWalletView.ContentType
    
    var body: some View {
        HStack(spacing: 16) {
            ForEach(HomeWalletView.ContentType.allCases, id: \.self) { contentType in
                viewForContentType(contentType)
                    .tag(contentType.rawValue)
            }
        }
    }
}

// MARK: - Private methods
private extension HomeWalletContentTypeSelectorView {
    @ViewBuilder
    func viewForContentType(_ contentType: HomeWalletView.ContentType) -> some View {
        Button {
            UDVibration.buttonTap.vibrate()
            selectedContentType = contentType
        } label: {
            Text(contentType.title)
                .foregroundStyle(getTintColorFor(isSelected: contentType == selectedContentType))
                .font(.currentFont(size: 16, weight: .medium))
        }
        .buttonStyle(.plain)
    }
    
    func getTintColorFor(isSelected: Bool) -> Color {
        isSelected ? .foregroundDefault : .foregroundSecondary
    }
}

#Preview {
    HomeWalletContentTypeSelectorView(selectedContentType: .constant(.tokens))
}
