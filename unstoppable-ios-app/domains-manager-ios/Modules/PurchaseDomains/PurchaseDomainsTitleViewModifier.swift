//
//  PurchaseDomainsTitleViewModifier.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 06.08.2024.
//

import SwiftUI

struct PurchaseDomainsTitleViewModifier: ViewModifier {
    
    @EnvironmentObject var tabRouter: HomeTabRouter
    @EnvironmentObject var stateManagerWrapper: NavigationStateManagerWrapper
    @EnvironmentObject var viewModel: PurchaseDomainsViewModel
    
    func body(content: Content) -> some View {
        content
            .trackNavigationControllerEvents(onDidNotFinishNavigationBack: setupTitleView)
            .onChange(of: tabRouter.walletViewNavPath) { _ in
                DispatchQueue.main.async {
                    updateTitleView()
                }
            }
            .onAppear(perform: onAppear)
        
    }
    
    func onAppear() {
        setupTitleView()
    }
    
    func setupTitleView() {
        withAnimation {
            stateManagerWrapper.navigationState?.setCustomTitle(customTitle: {
                DashedProgressView(configuration: .init(numberOfDashes: 3), progress: viewModel.progress)
            },
                                                                id: viewModel.id)
            updateTitleView()
        }
    }
    
    func updateTitleView() {
        if case .purchaseDomains(let destination) = tabRouter.walletViewNavPath.last {
            stateManagerWrapper.navigationState?.isTitleVisible = destination.isWithCustomTitle
        } else {
            stateManagerWrapper.navigationState?.isTitleVisible = true
        }
        
        stateManagerWrapper.navigationState?.yOffset = 2
    }
}


extension View {
    func purchaseDomainsTitleViewModifier() -> some View {
        modifier(PurchaseDomainsTitleViewModifier())
    }
}
