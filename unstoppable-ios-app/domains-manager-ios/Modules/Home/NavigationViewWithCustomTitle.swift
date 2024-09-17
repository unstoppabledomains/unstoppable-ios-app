//
//  NavigationViewWithCustomTitle.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 18.01.2024.
//

import SwiftUI

typealias EmptyNavigationPath = NavigationPathWrapper<Int>

struct NavigationViewWithCustomTitle<Content: View, Data>: View where Data: Hashable {
    
    @Environment(\.dismiss) var dismiss
    
    @ViewBuilder var content: () -> Content
    var navigationStateProvider: (NavigationStateManager)->()
    @Binding var path: NavigationPathWrapper<Data>
    private var navPath: Binding<NavigationPath> {
        Binding {
            path.navigationPath
        } set: { navPath in
            path.navigationPath = navPath
        }
        
    }
    @StateObject private var navigationState = NavigationStateManager()
    @State private var viewPresentationStyle: ViewPresentationStyle = .fullScreen
    
    var body: some View {
        NavigationStack(path: navPath) {
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


/// Navigation Path wrapper. Since iOS 18.0, If NavigationStack is used with array (like before) it now pushes two view controllers each time element appended to that error.
/// Issue is not reproducible if NavigationPath is used. This wrapper allows to avoid this bug while preserving existing functionality.
/// Navigation path should listen for didSet because user can swipe back manually and we need to adjust underlying array of typed elements.
struct NavigationPathWrapper<Data> where Data : Hashable {
    var navigationPath: NavigationPath = NavigationPath() {
        didSet {
            if navigationPath.count < navigationTypedPath.count {
                navigationTypedPath = Array(navigationTypedPath.prefix(navigationPath.count))
            } else if navigationPath.count > navigationTypedPath.count {
                Debugger.printFailure("Should never use NavigationLink. Only NavigationPathWrapper.", critical: true)
            }
        }
    }
    private var navigationTypedPath: [Data] = []
    
    var last: Data? { navigationTypedPath.last }
    var isEmpty: Bool { navigationPath.isEmpty }
    var count: Int { navigationPath.count }
    var indices: Range<Int> { navigationTypedPath.indices }
    
    mutating func append(_ item: Data) {
        navigationTypedPath.append(item)
        navigationPath.append(item)
    }
    
    mutating func removeAll() {
        navigationPath = NavigationPath()
    }
    
    mutating func removeLast() {
        navigationPath.removeLast()
    }
    
    func first(where isIncluded: (Data) -> Bool) -> Data? {
        navigationTypedPath.first(where: isIncluded)
    }
    
    subscript(index: Int) -> Data {
        navigationTypedPath[index]
    }
}

extension NavigationPathWrapper: Hashable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.navigationTypedPath == rhs.navigationTypedPath
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(navigationTypedPath)
    }
}
