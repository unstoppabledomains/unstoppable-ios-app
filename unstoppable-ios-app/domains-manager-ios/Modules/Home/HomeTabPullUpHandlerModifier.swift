//
//  HomeTabPullUpHandlerModifier.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.01.2024.
//

import SwiftUI

struct HomeTabPullUpHandlerModifier: ViewModifier {
    let tabRouter: HomeTabRouter
    let id = UUID()
    
    func body(content: Content) -> some View {
        content
            .viewPullUp(tabRouter.currentPullUp(id: id))
            .onAppear {
                tabRouter.registerTopView(id: id)
            }
            .onDisappear {
                tabRouter.unregisterTopView(id: id)
            }
    }
}

extension View {
    func pullUpHandler(_ tabRouter: HomeTabRouter) -> some View {
        modifier(HomeTabPullUpHandlerModifier(tabRouter: tabRouter))
    }
}
