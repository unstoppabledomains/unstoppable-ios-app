//
//  PurchaseDomainsRootView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 02.08.2024.
//

import SwiftUI

struct PurchaseDomainsRootView: View {
        
    @Environment(\.presentationMode) private var presentationMode
    @StateObject var viewModel: PurchaseDomainsViewModel
    @EnvironmentObject var tabRouter: HomeTabRouter
    @EnvironmentObject var stateManagerWrapper: NavigationStateManagerWrapper
    private let id = UUID().uuidString

    var body: some View {
        ZStack {
            PurchaseSearchDomainsView()
                .environmentObject(viewModel)
                .navigationBarTitleDisplayMode(.inline)
//                .navigationDestination(for: PurchaseDomains.NavigationDestination.self) { destination in
//                    PurchaseDomains.LinkNavigationDestination.viewFor(navigationDestination: destination)
//                        .ignoresSafeArea()
//                }
                .onChange(of: tabRouter.walletViewNavPath) { _ in
                    updateTitleView()
                }
                .trackNavigationControllerEvents(onDidNotFinishNavigationBack: updateTitleView)
            if viewModel.isLoading {
                ProgressView()
            }
        }
        .onChange(of: tabRouter.walletViewNavPath) { _ in
            if case .purchaseDomains(let destination) = tabRouter.walletViewNavPath.last {
                stateManagerWrapper.navigationState?.isTitleVisible = destination.isWithCustomTitle
            } else {
                stateManagerWrapper.navigationState?.isTitleVisible = true
            }
        }
        .displayError($viewModel.error)
        .allowsHitTesting(!viewModel.isLoading)
        .environmentObject(viewModel)
        .onAppear(perform: onAppear)
    }
}

// MARK: - Private methods
private extension PurchaseDomainsRootView {
    func onAppear() {
        setupTitleView()
    }
    
    func setupTitleView() {
        stateManagerWrapper.navigationState?.setCustomTitle(customTitle: { 
            DashedProgressView(progress: viewModel.progress)
        },
                                                            id: id)
        stateManagerWrapper.navigationState?.isTitleVisible = true
    }
    
    func updateTitleView() {
//        viewModel.navigationState?.yOffset = -2
//        withAnimation {
//            viewModel.navigationState?.isTitleVisible = viewModel.navPath.last?.isWithCustomTitle == true
//        }
    }
}

#Preview {
    PurchaseDomainsRootView(viewModel: PurchaseDomainsViewModel(router: MockEntitiesFabric.Home.createHomeTabRouter()))
}


struct DashedProgressView: View {
    
    let progress: Double
    
    var body: some View {
        Text("Progress \(progress)")
    }
    
}
