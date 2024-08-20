//
//  NavigationViewWithCustomTitle.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 18.01.2024.
//

import SwiftUI

typealias EmptyNavigationPath = Array<Int>

struct NavigationViewWithCustomTitle<Content: View, Data>: View where Data : MutableCollection, Data : RandomAccessCollection, Data : RangeReplaceableCollection, Data.Element : Hashable {
    
    @Environment(\.dismiss) var dismiss
    
    @ViewBuilder var content: () -> Content
    var navigationStateProvider: (NavigationStateManager)->()
    @Binding var path: Data
    @StateObject private var navigationState = NavigationStateManager()
    @State private var viewPresentationStyle: ViewPresentationStyle = .fullScreen

    var body: some View {
        NavigationStack(path: $path) {
            content()
                .navigationPopGestureDisabled(navigationState.navigationBackDisabled)
                .environmentObject(navigationState)
        }
        .overlay(alignment: .top, content: {
            if navigationState.isTitleVisible,
               let customTitle = navigationState.customTitle {
                AnyView(customTitle())
                    .offset(y: currentTitleOffset + navigationState.yOffset)
                    .frame(maxWidth: 240)
                    .id(navigationState.customViewID)
            }
        })
        .onAppear(perform: {
            navigationStateProvider(navigationState)
        })
        .onChange(of: navigationState.dismiss, perform: { newValue in
            if newValue {
                self.dismiss()
            }
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
        return 11
    }
}

#Preview {
    NavigationViewWithCustomTitle(content: {
        Text("Hello")
    }, navigationStateProvider: { _ in }, path: .constant(EmptyNavigationPath()))
}

final class NavigationStateManager: ObservableObject, Hashable {
    static func == (lhs: NavigationStateManager, rhs: NavigationStateManager) -> Bool {
        lhs.customViewID == rhs.customViewID
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(customViewID)
    }
    
    @Published var isTitleVisible: Bool = false
    @Published var yOffset: CGFloat = 0
    @Published var dismiss: Bool = false
    @Published var navigationBackDisabled: Bool = false
    @Published private(set) var customTitle: (() -> any View)?
    private(set) var customViewID: String?
    
    
    func setCustomTitle(customTitle: (() -> any View)?,
                        id: String) {
        self.customTitle = customTitle
        customViewID = id
    }
}

final class NavigationStateManagerWrapper: ObservableObject {
    
    @Published var navigationState: NavigationStateManager?
    
}
