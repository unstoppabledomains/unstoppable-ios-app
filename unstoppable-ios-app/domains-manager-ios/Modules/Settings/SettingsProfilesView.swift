//
//  SettingsProfilesView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 03.05.2024.
//

import SwiftUI

struct SettingsProfilesView: View, ViewAnalyticsLogger {
    
    @Environment(\.analyticsViewName) var analyticsName
    @Environment(\.analyticsAdditionalProperties) var additionalAppearAnalyticParameters
    @EnvironmentObject private var tabRouter: HomeTabRouter

    let profiles: [UserProfile]
    private let gridColumns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        LazyVGrid(columns: gridColumns, spacing: 16) {
            ForEach(profiles, id: \.id) { profile in
                tileViewForProfile(profile)
            }
        }
    }
}

// MARK: - Private methods
private extension SettingsProfilesView {
    @ViewBuilder
    func tileViewForProfile(_ profile: UserProfile) -> some View {
        switch profile {
        case .wallet(let wallet):
            titleViewForWalletProfile(profile, wallet: wallet)
        case .webAccount(let firebaseUser):
            titleViewForFirebaseUserProfile(profile,
                                            firebaseUser: firebaseUser)
        }
    }
    
    @ViewBuilder
    func titleViewForWalletProfile(_ profile: UserProfile,
                                   wallet: WalletEntity) -> some View {
        Button {
            logButtonPressedAnalyticEvents(button: .walletInList)
            UDVibration.buttonTap.vibrate()
            tabRouter.walletViewNavPath.append(.walletDetails(wallet))
        } label: {
            SettingsProfileTileView(profile: profile)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    func titleViewForFirebaseUserProfile(_ profile: UserProfile,
                                         firebaseUser: FirebaseUser) -> some View {
        Menu {
            Button(role: .destructive) {    
                askToLogOut()
            } label: {
                Label(String.Constants.logOut.localized(), systemImage: "rectangle.portrait.and.arrow.right")
            }
        } label: {
            SettingsProfileTileView(profile: profile)
                .contentShape(Rectangle())
        }
        .onButtonTap {
            logButtonPressedAnalyticEvents(button: .logOut)
        }
    }
    
    func askToLogOut() {
        Task { @MainActor in
            guard let topVC = appContext.coreAppCoordinator.topVC else { return }
            
            do {
                try await appContext.pullUpViewService.showLogoutConfirmationPullUp(in: topVC)
                await topVC.dismissPullUpMenu()
                try await appContext.authentificationService.verifyWith(uiHandler: topVC, purpose: .confirm)
                appContext.firebaseParkedDomainsAuthenticationService.logOut()
                appContext.toastMessageService.showToast(.userLoggedOut, isSticky: false)
            }
        }
    }
}

#Preview {
    SettingsProfilesView(profiles: [MockEntitiesFabric.Profile.createWalletProfile(),
                                    MockEntitiesFabric.Profile.createExternalWalletProfile(),
                                    MockEntitiesFabric.Profile.createWebAccountProfile(),
                                    ])
}
