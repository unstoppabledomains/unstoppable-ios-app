//
//  MPCResetPasswordRootView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 24.10.2024.
//

import SwiftUI

struct MPCResetPasswordRootView: View {
    
    @Environment(\.presentationMode) private var presentationMode
    @StateObject private var viewModel: MPCResetPasswordViewModel
    
    var body: some View {
        NavigationViewWithCustomTitle(content: {
            ZStack {
                MPCResetPasswordEnterPasswordView(email: viewModel.resetPasswordData.email)
                    .environmentObject(viewModel)
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationDestination(for: MPCResetPasswordFlow.NavigationDestination.self) { destination in
                        MPCResetPasswordFlow.LinkNavigationDestination.viewFor(navigationDestination: destination)
                            .ignoresSafeArea()
                            .environmentObject(viewModel)
                    }
                    .onChange(of: viewModel.navPath) { _ in
                        updateTitleView()
                    }
                    .trackNavigationControllerEvents(onDidNotFinishNavigationBack: updateTitleView)
                if viewModel.isLoading {
                    ProgressView()
                }
            }
        }, navigationStateProvider: { navigationState in
            self.viewModel.navigationState = navigationState
        }, path: $viewModel.navPath)
        .interactiveDismissDisabled()
        .displayError($viewModel.error)
        .allowsHitTesting(!viewModel.isLoading)
    }
    
    init(resetPasswordData: MPCResetPasswordData,
         resetResultCallback: @escaping MPCResetPasswordFlow.FlowResultCallback) {
        self._viewModel = StateObject(wrappedValue: MPCResetPasswordViewModel(resetPasswordData: resetPasswordData,
                                                                              resetResultCallback: resetResultCallback))
    }
}

// MARK: - Private methods
private extension MPCResetPasswordRootView {
    func updateTitleView() {
        viewModel.navigationState?.yOffset = -2
        withAnimation {
            viewModel.navigationState?.isTitleVisible = viewModel.navPath.last?.isWithCustomTitle == true
        }
    }
}

#Preview {
    MPCResetPasswordRootView(resetPasswordData: .init(email: "",
                                                      recoveryToken: ""),
                             resetResultCallback: { _ in })
}
