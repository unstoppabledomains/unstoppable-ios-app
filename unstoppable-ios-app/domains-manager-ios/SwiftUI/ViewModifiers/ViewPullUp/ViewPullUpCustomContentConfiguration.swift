//
//  ViewPullUpCustomContentConfiguration.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 24.01.2024.
//

import SwiftUI

struct ViewPullUpCustomContentConfiguration {
    @ViewBuilder var content: () -> any View
    let height: CGFloat
}

// MARK: - Open methods
extension ViewPullUpCustomContentConfiguration {
    static func loadingIndicator() -> ViewPullUpCustomContentConfiguration {
        .init(content: {
            ZStack {
                ProgressView()
                    .tint(Color.foregroundDefault)
            }
            .backgroundStyle(Color.backgroundDefault)
        }, height: 428)
    }
}
