//
//  SettingsView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 03.05.2024.
//

import SwiftUI
import MessageUI

struct SettingsView: View, ViewAnalyticsLogger {
    
    @Environment(\.userProfilesService) var userProfilesService
    @EnvironmentObject private var tabRouter: HomeTabRouter
    
    @State private var profiles: [UserProfile] = []
    @State private var pullUp: ViewPullUpConfigurationType?
    @State private var error: Error?
    private let ecommAuthenticator = EcommAuthenticator()
    var analyticsName: Analytics.ViewName { .settings }

    var body: some View {
        contentView()
            .background(Color.backgroundDefault)
            .onReceive(userProfilesService.profilesPublisher.receive(on: DispatchQueue.main), perform: { profiles in
                self.profiles = profiles
            })
            .displayError($error)
            .navigationTitle(String.Constants.settings.localized())
            .navigationBarTitleDisplayMode(.large)
            .viewPullUp($pullUp)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing, content: topBarButton)
            }
            .navigationDestination(for: SettingsNavigationDestination.self) { destination in
                SettingsLinkNavigationDestination.viewFor(navigationDestination: destination)
                    .ignoresSafeArea()
            }
    }
    
}

// MARK: - Private methods
private extension SettingsView {
    @ViewBuilder
    func contentView() -> some View {
        ScrollView {
            PublicProfileSeparatorView(verticalPadding: 0)
                .padding(.bottom, 20)
            profilesListView()
            PublicProfileSeparatorView(verticalPadding: 0)
                .padding(.vertical, 20)
            moreSection()
            othersSection()
                .padding(.top, 12)
            footerView()
                .padding(.top, 20)
        }
        .padding()
    }
    
    @ViewBuilder
    func sectionHeader(title: String) -> some View {
        HStack {
            Text(title)
                .font(.currentFont(size: 20, weight: .bold))
                .foregroundStyle(Color.foregroundDefault)
            Spacer()
        }
    }
    
    var webUser: FirebaseUser? {
        for profile in profiles {
            if case .webAccount(let firebaseUser) = profile {
                return firebaseUser
            }
        }
        return nil
    }
    
    @ViewBuilder
    func topBarButton() -> some View {
        if let webUser {
            webUserActionButton(webUser)
        } else {
            loginButton()
        }
    }
    
    @ViewBuilder
    func webUserActionButton(_ webUser: FirebaseUser) -> some View {
        Menu {
            Button(role: .destructive) {
                askToLogOut()
            } label: {
                Label(String.Constants.logOut.localized(), systemImage: "rectangle.portrait.and.arrow.right")
            }
        } label: {
            topActinTextView(text: webUser.displayName)
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
    
    @ViewBuilder
    func loginButton() -> some View {
        Button {
            UDVibration.buttonTap.vibrate()
            pullUp = .default(.loginOptionsSelectionPullUp(selectionCallback: didSelectToAuthWith))
        } label: {
            topActinTextView(text: String.Constants.login.localized())
        }
    }
    
    @ViewBuilder
    func topActinTextView(text: String) -> some View {
        Text(text)
            .font(.currentFont(size: 16, weight: .medium))
            .foregroundStyle(Color.foregroundAccent)
            .frame(maxWidth: 150)
    }
    
    @MainActor
    func didSelectToAuthWith(provider: LoginProvider) {
        switch provider {
        case .email:
            tabRouter.walletViewNavPath.append(HomeWalletNavigationDestination.login(mode: .email, callback: handleLoginResult))
        case .google:
            ecommAuthenticator.loginWithGoogle(resultCallback: didAuthorise)
        case .twitter:
            ecommAuthenticator.loginWithTwitter(resultCallback: didAuthorise)
        case .apple:
            ecommAuthenticator.loginWithApple(resultCallback: didAuthorise)
        }
    }
    
    func didAuthorise(_ result: EcommAuthenticator.AuthResult) {
        switch result {
        case .authorised(let provider):
            tabRouter.walletViewNavPath.append(HomeWalletNavigationDestination.login(mode: .authorized(provider), callback: handleLoginResult))
        case .failed(let error):
            self.error = error
        }
    }
    
    func handleLoginResult(_ login: LoginFlowNavigationController.LogInResult) {
        switch login {
        case .cancel, .failedToLoadParkedDomains:
            return
        case .loggedIn:
            tabRouter.walletViewNavPath.removeAll()
        }
    }
}

// MARK: - Profiles
private extension SettingsView {
    @ViewBuilder
    func profilesListView() -> some View {
        SettingsProfilesView(profiles: profiles)
    }
}

// MARK: - More
private extension SettingsView {
    @ViewBuilder
    func moreSection() -> some View {
        VStack(spacing: 16) {
            sectionHeader(title: String.Constants.more.localized())
            moreItemsList()
        }
    }
    
    var currentMoreItems: [MoreSectionItems] {
        var items: [MoreSectionItems] = [.security]
        #if TESTFLIGHT
        items.append(.testnet(isOn: User.instance.getSettings().isTestnetUsed, callback: setTestnet))
        #endif
        return items
    }
    
    @ViewBuilder
    func moreItemsList() -> some View {
        UDCollectionSectionBackgroundView {
            VStack(alignment: .center, spacing: 0) {
                ForEach(currentMoreItems, id: \.id) { moreItem in
                    listViewFor(moreItem: moreItem)
                }
            }
        }
    }
    
    @ViewBuilder
    func listViewFor(moreItem: MoreSectionItems) -> some View {
        UDCollectionListRowButton(content: {
            UDListItemView(title: moreItem.title,
                           value: moreItem.value,
                           imageType: .image(moreItem.icon),
                           imageStyle: .centred(foreground: .white, background: moreItem.backgroundColor, bordered: true),
                           rightViewStyle: moreItem.rightViewStyle)
                        .udListItemInCollectionButtonPadding()
        }, callback: {
            UDVibration.buttonTap.vibrate()
            logButtonPressedAnalyticEvents(button: moreItem.analyticsName)
            didSelect(moreItem: moreItem)
        })
        .padding(EdgeInsets(4))
    }
    
    func setTestnet(on isOn: Bool) {
        var settings = User.instance.getSettings()
        switch isOn {
        case false: settings.networkType = .mainnet
        case true: settings.networkType = .testnet
        }
        User.instance.update(settings: settings)
        Storage.instance.cleanAllCache()
        appContext.firebaseParkedDomainsAuthenticationService.logOut()
        appContext.messagingService.logout()
        Task { await appContext.userDataService.getLatestAppVersion() }
        appContext.walletsDataService.didChangeEnvironment()
        appContext.notificationsService.updateTokenSubscriptions()
    }
    
    func didSelect(moreItem: MoreSectionItems) {
        switch moreItem {
        case .security:
            return
        case .testnet:
            return
        }
    }
}

// MARK: - Other
private extension SettingsView {
    @ViewBuilder
    func othersSection() -> some View {
        otherItemsList()
    }
    
    @ViewBuilder
    func otherItemsList() -> some View {
        UDCollectionSectionBackgroundView {
            VStack(alignment: .center, spacing: 0) {
                ForEach(SettingsItems.allCases, id: \.self) { moreItem in
                    listViewFor(otherItem: moreItem)
                }
            }
        }
    }
    
    @ViewBuilder
    func listViewFor(otherItem: SettingsItems) -> some View {
        UDCollectionListRowButton(content: {
            UDListItemView(title: otherItem.title,
                           titleColor: .foregroundAccent,
                           imageType: .image(otherItem.icon),
                           imageStyle: .centred(offset: .init(8), foreground: .foregroundAccent, background: .clear, bordered: false))
            .padding(.init(horizontal: 12, vertical: 4))
        }, callback: {
            UDVibration.buttonTap.vibrate()
            logButtonPressedAnalyticEvents(button: otherItem.analyticsName)
            didSelect(otherItem: otherItem)
        })
        .padding(EdgeInsets(4))
    }
    
    func didSelect(otherItem: SettingsItems) {
        Task { @MainActor in
            switch otherItem {
            case .rateUs:
                AppReviewService.shared.requestToWriteReviewInAppStore()
            case .learn:
                openLink(.learn)
            case .twitter:
                openUDTwitter()
            case .support:
                openFeedbackMailForm()
            case .legal:
                pullUp = .default(.legalSelectionPullUp(selectionCallback: didSelectLegalType))
            }
        }
    }
    
    @MainActor
    func didSelectLegalType(_ legalType: LegalType) {
        switch legalType {
        case .termsOfUse:
            openLink(.termsOfUse)
        case .privacyPolicy:
            openLink(.privacyPolicy)
        }
    }
    
    @MainActor
    func openFeedbackMailForm() {
        let mail = MFMailComposeViewController()
        
        mail.setToRecipients([Constants.UnstoppableSupportMail])
        mail.setSubject("Unstoppable Domains App Feedback - iOS (\(UserDefaults.buildVersion))")
        
        appContext.coreAppCoordinator.topVC?.present(mail, animated: true)
    }
}

// MARK: - Footer
private extension SettingsView {
    @ViewBuilder
    func footerView() -> some View {
        VStack(spacing: 0) {
            Text(String.Constants.youAreUnstoppable.localized())
                .foregroundStyle(Color.foregroundDefault)
                .frame(height: 20)
            Text(UserDefaults.buildVersion)
                .foregroundStyle(Color.foregroundMuted)
                .frame(height: 20)
        }
        .font(.currentFont(size: 14, weight: .medium))
    }
}

// MARK: - Entities
private extension SettingsView {
    enum MoreSectionItems: Identifiable {
        var id: String {
            switch self {
            case .security:
                return "security"
            case .testnet:
                return "testnet"
            }
        }
        case security
        case testnet(isOn: Bool, callback: (Bool)->())
        
        var title: String {
            switch self {
            case .security:
                return String.Constants.settingsSecurity.localized()
            case .testnet:
                return "Testnet"
            }
        }
        
        var icon: Image {
            switch self {
            case .security:
                return .settingsIconLock
            case .testnet:
                return .settingsIconTestnet
            }
        }
        
        var backgroundColor: Color {
            switch self {
            case .security:
                return .brandDeepBlue
            case .testnet:
                return .brandSkyBlue
            }
        }
       
        var value: String? {
            switch self {
            case .security:
                return User.instance.getSettings().touchIdActivated ? (appContext.authentificationService.biometricsName ?? "") : String.Constants.settingsSecurityPasscode.localized()
            case .testnet:
                return nil
            }
        }
        
        var rightViewStyle: UDListItemView.RightViewStyle {
            switch self {
            case .security:
                return .chevron
            case .testnet(let isOn, let callback):
                return .toggle(isOn: isOn, callback: callback)
            }
        }
        
        enum ControlType {
            case empty, chevron(value: String?), switcher(isOn: Bool)
        }
        
        var analyticsName: Analytics.Button {
            switch self {
            case .security:
                return .settingsSecurity
            case .testnet:
                return .settingsTestnet
            }
        }
    }
    
    enum SettingsItems: CaseIterable {
        case rateUs, learn, twitter, support, legal
        
        var title: String {
            switch self {
            case .rateUs:
                return String.Constants.rateUs.localized()
            case .learn:
                return String.Constants.settingsLearn.localized()
            case .twitter:
                return String.Constants.settingsFollowTwitter.localized()
            case .support:
                return String.Constants.settingsSupportNFeedback.localized()
            case .legal:
                return String.Constants.settingsLegal.localized()
            }
        }
        
        var icon: Image {
            switch self {
            case .rateUs:
                return .iconStar24
            case .learn:
                return .settingsIconLearn
            case .twitter:
                return .settingsIconTwitter
            case .support:
                return .settingsIconFeedback
            case .legal:
                return .settingsIconLegal
            }
        }
        
        var analyticsName: Analytics.Button {
            switch self {
            case .rateUs:
                return .settingsRateUs
            case .learn:
                return .settingsLearn
            case .twitter:
                return .settingsTwitter
            case .support:
                return .settingsSupport
            case .legal:
                return .settingsLegal
            }
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
