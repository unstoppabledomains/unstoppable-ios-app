//
//  PurchaseDomainsTitleView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 06.08.2024.
//

import SwiftUI

struct PurchaseDomainsTitleView: View {
    
    @EnvironmentObject var tabRouter: HomeTabRouter
    @EnvironmentObject var viewModel: PurchaseDomainsViewModel
    @State private var swipeBackProgress: Double = 0.0
    
    var body: some View {
        DashedProgressView(configuration: .init(numberOfDashes: 3),
                           progress: viewModel.progressFor(swipeBackProgress: swipeBackProgress))
        .trackNavigationControllerEvents(onDidBackGestureProgress: didSwipeBackWithProgress)
        .onChange(of: tabRouter.walletViewNavPath) { _ in
            DispatchQueue.main.async {
                swipeBackProgress = 0
            }
        }
    }
    
    private func didSwipeBackWithProgress(_ progress: Double) {
        swipeBackProgress = progress
    }
}
