//
//  NavigationViewWithCustomTitle.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 18.01.2024.
//

import SwiftUI

struct NavigationViewWithCustomTitle<Content: View>: View {
    
    @ViewBuilder var content: () -> Content
    var navigationStateProvider: (NavigationStateManager)->()
    @StateObject private var navigationState = NavigationStateManager()

    var body: some View {
        NavigationStack {
            content()
        }
        .overlay(alignment: .top, content: {
            if navigationState.isTitleVisible,
            let customTitle = navigationState.customTitle {
                AnyView(customTitle())
                    .offset(y: currentTitleOffset)
            }
        })
        .onAppear(perform: {
            navigationStateProvider(navigationState)
        })
    }
    
    @MainActor
    private var currentTitleOffset: CGFloat {
        if #available(iOS 17, *) {
            if (SceneDelegate.shared?.window?.safeAreaInsets.bottom ?? 0) > 0 {
                return 6
            }
            return 11
        } else {
            return 11
        }
    }
}

#Preview {
    NavigationViewWithCustomTitle(content: {
        Text("Hello")
    }, navigationStateProvider: { _ in })
}

class NavigationStateManager: ObservableObject {
    @Published var isTitleVisible: Bool = false
    @Published var customTitle: (() -> any View)?
}