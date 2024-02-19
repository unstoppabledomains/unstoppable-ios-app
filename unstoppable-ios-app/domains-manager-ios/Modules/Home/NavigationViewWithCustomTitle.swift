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
    @Binding var path: NavigationPath 
    @StateObject private var navigationState = NavigationStateManager()
    @State private var viewPresentationStyle: ViewPresentationStyle = .fullScreen

    var body: some View {
        NavigationStack(path: $path) {
            content()
                .environmentObject(navigationState)
        }
        .overlay(alignment: .top, content: {
            if navigationState.isTitleVisible,
               let customTitle = navigationState.customTitle {
                AnyView(customTitle())
                    .offset(y: currentTitleOffset)
                    .frame(maxWidth: 240)
            }
        })
        .onAppear(perform: {
            navigationStateProvider(navigationState)
        })
        .presentationStyleChecker(viewPresentationStyle: $viewPresentationStyle)
    }
    
    @MainActor
    private var currentTitleOffset: CGFloat {
        switch viewPresentationStyle {
        case .sheet:
            currentDeviceOffset + 10
        case .fullScreen:
            currentDeviceOffset
        }
    }
    
    @MainActor
    private var currentDeviceOffset: CGFloat {
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
    }, navigationStateProvider: { _ in }, path: .constant(.init()))
}

final class NavigationStateManager: ObservableObject {
    @Published var isTitleVisible: Bool = false
    @Published private(set) var customTitle: (() -> any View)?
    private(set) var customViewID: String?
    
    func setCustomTitle(customTitle: (() -> any View)?,
                        id: String) {
        self.customTitle = customTitle
        customViewID = id
    }
}
