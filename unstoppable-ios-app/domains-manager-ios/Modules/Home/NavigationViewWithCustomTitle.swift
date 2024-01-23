//
//  NavigationViewWithCustomTitle.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 18.01.2024.
//

import SwiftUI

struct NavigationViewWithCustomTitle<Content: View, Header: View>: View {
    
    @ViewBuilder var content: () -> Content
    @ViewBuilder var customTitle: () -> Header
    let isTitleVisible: Bool

    var body: some View {
        WrappedNavigationView {
            content()
        }
        .overlay(alignment: .top, content: {
            if isTitleVisible {
                customTitle()
                    .offset(y: currentTitleOffset)
            }
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
    }, customTitle: {
        Text("Custom PopUp View!")
    }, isTitleVisible: true)
}


private struct WrappedNavigationView<Content: View>: View {
    
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        if #available(iOS 16.0, *) {
            NavigationStack {
                content()
            }
        } else {
            NavigationView {
                content()
            }
        }
    }
}
