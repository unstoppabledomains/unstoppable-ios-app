//
//  HomeWalletWalletSelectionView:.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.01.2024.
//

import SwiftUI

struct UserProfileSelectionView: View, ViewAnalyticsLogger {
    
    @MainActor
    static func viewController(mode: UserProfileSelectionView.Mode) -> UIViewController {
        let view = UserProfileSelectionView(mode: mode)
            .adaptiveSheet()
        let vc = UIHostingController(rootView: view)
        return vc
    }
    
    @Environment(\.userProfileService) private var userProfileService
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var tabRouter: HomeTabRouter

    @State private var profiles: [UserProfile] = []
    @State private var selectedProfile: UserProfile? = nil
    var mode: Mode = .default
    var analyticsName: Analytics.ViewName { .profileSelection }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                titleView()
                selectedProfileView()
                profilesListView()
                addWalletView()
            }
            .padding()
        }
        .background(Color.backgroundDefault)
        .onAppear(perform: onAppear)
        .trackAppearanceAnalytics(analyticsLogger: self)
    }
    
    enum Mode {
        case `default`, walletProfileSelection(selectedWallet: WalletEntity)
    }
    
}

// MARK: - Private methods
private extension UserProfileSelectionView {
    func onAppear() {
        let profiles = userProfileService.profiles
        switch mode {
        case .default:
            self.selectedProfile = userProfileService.selectedProfile
            self.profiles = profiles.filter({ $0.id != selectedProfile?.id })
        case .walletProfileSelection(let selectedWallet):
            self.selectedProfile = .wallet(selectedWallet)
            self.profiles = profiles.filter({ $0.isWalletProfile && $0.id != selectedProfile?.id })
        }
    }
    
    @ViewBuilder
    func titleView() -> some View {
        Text(String.Constants.profiles.localized())
            .font(.currentFont(size: 22, weight: .bold))
            .foregroundStyle(Color.foregroundDefault)
            .padding(EdgeInsets(top: 8, leading: 0, bottom: 0, trailing: 0))
    }
    
    @ViewBuilder
    func selectedProfileView() -> some View {
        if let selectedProfile {
            UDCollectionSectionBackgroundView {
                listViewFor(profile: selectedProfile)
                    .allowsHitTesting(false)
            }
        }
    }
    
    @ViewBuilder
    func profilesListView() -> some View {
        if !profiles.isEmpty {
            UDCollectionSectionBackgroundView {
                VStack(alignment: .center, spacing: 0) {
                    ForEach(profiles, id: \.id) { profile in
                        listViewFor(profile: profile)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    func listViewFor(profile: UserProfile) -> some View {
        UDCollectionListRowButton(content: {
            UserProfileSelectionRowView(profile: profile,
                                        isSelected: profile.id == selectedProfile?.id)
            .udListItemInCollectionButtonPadding()
        }, callback: {
            UDVibration.buttonTap.vibrate()
            presentationMode.wrappedValue.dismiss()
            userProfileService.setActiveProfile(profile)
            logButtonPressedAnalyticEvents(button: .profileSelected, parameters: [.profileId : profile.id])
        })
        .padding(EdgeInsets(4))
    }
    
    @ViewBuilder
    func addWalletView() -> some View {
        if case .default = mode {
            UDCollectionSectionBackgroundView {
                Button {
                    UDVibration.buttonTap.vibrate()
                    tabRouter.runAddWalletFlow(initialAction: .showAllAddWalletOptionsPullUp)
                    logButtonPressedAnalyticEvents(button: .addWallet)
                } label: {
                    HStack(spacing: 16) {
                        Image.plusIconNav
                            .resizable()
                            .squareFrame(20)
                        
                        Text(String.Constants.add.localized())
                            .font(.currentFont(size: 16, weight: .medium))
                        Spacer()
                    }
                    .foregroundStyle(Color.foregroundAccent)
                    .padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 0))
                    .frame(height: 56)
                }
            }
        }
    }
}

#Preview {
    UserProfileSelectionView()
}
