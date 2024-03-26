//
//  ConfirmSendTokenViewsBuilderProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.03.2024.
//

import SwiftUI

// MARK: - Private methods
protocol ConfirmSendTokenViewsBuilderProtocol { }

extension ConfirmSendTokenViewsBuilderProtocol {
    @ViewBuilder
    func primaryTextView(_ text: String) -> some View {
        Text(text)
            .font(.currentFont(size: 28, weight: .medium))
            .foregroundStyle(Color.foregroundDefault)
            .frame(height: 36)
    }
    
    @ViewBuilder
    func secondaryTextView(_ text: String) -> some View {
        Text(text)
            .font(.currentFont(size: 16))
            .foregroundStyle(Color.foregroundSecondary)
            .frame(height: 24)
    }
}
