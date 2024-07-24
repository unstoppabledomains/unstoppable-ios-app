//
//  SendCryptoAssetRootView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 20.03.2024.
//

import SwiftUI

struct SendCryptoAssetRootView: View {
    
    @Environment(\.presentationMode) private var presentationMode
    @StateObject var viewModel: SendCryptoAssetViewModel
    @StateObject private var infuraFlagTracker = UDMaintenanceModeFeatureFlagTracker(featureFlag: .isMaintenanceInfuraEnabled)

    var body: some View {
        NavigationViewWithCustomTitle(content: {
            ZStack {
                contentView()
                if viewModel.isLoading {
                    ProgressView()
                }
            }
        }, navigationStateProvider: { navigationState in
            self.viewModel.navigationState = navigationState
        }, path: $viewModel.navPath)
        .interactiveDismissDisabled(!viewModel.navPath.isEmpty)
        .displayError($viewModel.error)
        .allowsHitTesting(!viewModel.isLoading)
    }
    
}

// MARK: - Private methods
private extension SendCryptoAssetRootView {
    func updateTitleView() {
        viewModel.navigationState?.yOffset = -2
        withAnimation {
            viewModel.navigationState?.isTitleVisible = viewModel.navPath.last?.isWithCustomTitle == true
        }
    }
}

// MARK: - Private methods
private extension SendCryptoAssetRootView {
    var isMaintenanceOnForSelectedWallet: Bool {
        switch viewModel.sourceWallet.udWallet.type {
        case .mpc:
            return infuraFlagTracker.maintenanceData?.isCurrentlyEnabled == true
        case .externalLinked:
            return false
        default:
            return infuraFlagTracker.maintenanceData?.isCurrentlyEnabled == true
        }
    }
    
    var affectedServiceMaintenanceData: MaintenanceModeData? {
        infuraFlagTracker.maintenanceData
    }
    
    @ViewBuilder
    func contentView() -> some View {
        if isMaintenanceOnForSelectedWallet {
            MaintenanceDetailsFullView(serviceType: .sendCrypto,
                                           maintenanceData: affectedServiceMaintenanceData)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    closeButton()
                }
            }
        } else {
            sendCryptoFlowView()
        }
    }
    
    @ViewBuilder
    func sendCryptoFlowView() -> some View {
        SendCryptoAssetSelectReceiverView()
            .environmentObject(viewModel)
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: SendCryptoAsset.NavigationDestination.self) { destination in
                SendCryptoAsset.LinkNavigationDestination.viewFor(navigationDestination: destination)
                    .ignoresSafeArea()
                    .environmentObject(viewModel)
            }
            .onChange(of: viewModel.navPath) { _ in
                updateTitleView()
            }
            .trackNavigationControllerEvents(onDidNotFinishNavigationBack: updateTitleView)
    }
    
    @ViewBuilder
    func closeButton() -> some View {
        CloseButtonView {
            presentationMode.wrappedValue.dismiss()
        }
    }
}

#Preview {
    PresentAsModalPreviewView {
        SendCryptoAssetRootView(viewModel: SendCryptoAssetViewModel(initialData: .init(sourceWallet:  MockEntitiesFabric.Wallet.mockEntities()[0])))
    }
}
