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
    
    @State var initialAction: InitialAction
    
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
            .onAppear(perform: onAppear)
    }
    
}

// MARK: - Private methods
private extension SettingsView {
    func onAppear() {
        Task {
            await Task.sleep(seconds: 0.2)
            checkIfCanAddWalletAndPerform(action: initialAction, isImportOnly: true)
            initialAction = .none
        }
    }
    
    @ViewBuilder
    func contentView() -> some View {
        ScrollView {
            PublicProfileSeparatorView(verticalPadding: 0)
                .padding(.vertical, 20)
            profilesListView()
            PublicProfileSeparatorView(verticalPadding: 0)
                .padding(.vertical, 20)
            moreSection()
            othersSection()
                .padding(.top, 12)
            footerView()
                .padding(.top, 20)
        }
        .padding(.horizontal, 16)
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
        profilesHeaderView()
        SettingsProfilesView(profiles: profiles)
    }
    
    @ViewBuilder
    func profilesHeaderView() -> some View {
        HStack(spacing: 8) {
            Text(String.Constants.profiles.localized())
                .textAttributes(color: .foregroundDefault,
                                fontSize: 20,
                                fontWeight: .bold)
            walletActionsButton()
            Spacer()
            addWalletsButton()
        }
        .frame(height: 24)
        .padding(.bottom, 16)
    }
    
    @ViewBuilder
    func walletActionsButton() -> some View {
        if appContext.networkReachabilityService?.isReachable == true,
           !appContext.udWalletsService.fetchCloudWalletClusters().isEmpty {
            Menu {
                Button(String.Constants.manageICloudBackups.localized(),
                       systemImage: "cloud") {
                    UDVibration.buttonTap.vibrate()
                    logButtonPressedAnalyticEvents(button: .manageICloudBackups)
                    showManageBackupsAction()
                }
            } label: {
                Image.dotsCircleIcon
                    .resizable()
                    .squareFrame(24)
                    .foregroundStyle(Color.foregroundSecondary)
            }
            .onButtonTap()
        }
    }
    
    @ViewBuilder
    func addWalletsButton() -> some View {
        Button {
            UDVibration.buttonTap.vibrate()
            checkIfCanAddWalletAndPerform(action: .showImportWalletOptionsPullUp, isImportOnly: false)
        } label: {
            HStack(spacing: 8) {
                Text(String.Constants.add.localized())
                    .font(.currentFont(size: 16, weight: .medium))
                Image.plusIconNav
                    .resizable()
                    .squareFrame(24)
            }
            .foregroundStyle(Color.foregroundSecondary)
        }
        .buttonStyle(.plain)
    }
    
    func showManageBackupsAction() {
        Task {
            guard let view = appContext.coreAppCoordinator.topVC else { return }
            let udWalletsService = appContext.udWalletsService
            
            guard iCloudWalletStorage.isICloudAvailable() else {
                view.showICloudDisabledAlert()
                return
            }
            
            do {
                let action = try await appContext.pullUpViewService.showManageBackupsSelectionPullUp(in: view)
                
                switch action {
                case .restore:
                    let backups = udWalletsService.fetchCloudWalletClusters().sorted(by: {
                        if $0.isCurrent || $1.isCurrent {
                            return $0.isCurrent
                        }
                        return $0.date > $1.date
                    })
                    
                    if backups.count == 1 {
                        await view.dismissPullUpMenu()
                        restoreWalletFrom(backup: backups[0])
                    } else {
                        let displayBackups = backups.map({ ICloudBackupDisplayInfo(date: $0.date, backedUpWallets: $0.wallets, isCurrent: $0.isCurrent) })
                        let selectedBackup = try await appContext.pullUpViewService.showRestoreFromICloudBackupSelectionPullUp(in: view, backups: displayBackups)
                        if let index = displayBackups.firstIndex(where: { $0 == selectedBackup }) {
                            await view.dismissPullUpMenu()
                            restoreWalletFrom(backup: backups[index])
                        }
                    }
                case .delete:
                    try await appContext.pullUpViewService.showDeleteAllICloudBackupsPullUp(in: view)
                    await view.dismissPullUpMenu()
                    try await appContext.authentificationService.verifyWith(uiHandler: view, purpose: .confirm)
                    udWalletsService.eraseAllBackupClusters()
                    SecureHashStorage.clearPassword()
                }
            } catch { }
        }
    }
    
    func restoreWalletFrom(backup: UDWalletsService.WalletCluster) {
        guard let view = appContext.coreAppCoordinator.topVC else { return }

        UDRouter().showRestoreWalletsFromBackupScreen(for: backup,
                                                      walletsRestoredCallback: {
            showICloudBackupRestoredToast()
            AppReviewService.shared.appReviewEventDidOccurs(event: .didRestoreWalletsFromBackUp)
        }, in: view)
    }
    
    func showICloudBackupRestoredToast() {
        Task {
            await MainActor.run {
                appContext.toastMessageService.showToast(.iCloudBackupRestored, isSticky: false)
            }
        }
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
            tabRouter.walletViewNavPath.append(HomeWalletNavigationDestination.securitySettings)
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

// MARK: - Private methods
private extension SettingsView {
    func checkIfCanAddWalletAndPerform(action: InitialAction, isImportOnly: Bool) {
        guard appContext.udWalletsService.canAddNewWallet else {
            showWalletsNumberLimitReachedPullUp()
            return
        }
        
        switch action {
        case .none:
            return
        case .showImportWalletOptionsPullUp:
            showAddWalletPullUp(isImportOnly: isImportOnly)
        case .showAllAddWalletOptionsPullUp:
            showAddWalletPullUp(isImportOnly: false)
        case .importWallet:
            importNewWallet()
        case .connectWallet:
            connectNewWallet()
        case .createNewWallet:
            createNewWallet()
        }
    }
    
    func showAddWalletPullUp(isImportOnly: Bool) {
        guard let view = appContext.coreAppCoordinator.topVC else { return }

        Task {
            let actions: [WalletDetailsAddWalletAction]
            if isImportOnly {
                actions = [.mpc, .recoveryOrKey, .connect]
            } else {
                actions = WalletDetailsAddWalletAction.allCases
            }
            do {
                let action = try await appContext.pullUpViewService.showAddWalletSelectionPullUp(in: view,
                                                                                                 presentationOptions: .default,
                                                                                                 actions: actions)
                await view.dismissPullUpMenu()
                didSelectAddWalletAction(action)
            } catch { }
        }
    }
    
    func didSelectAddWalletAction(_ action: WalletDetailsAddWalletAction) {
        Task {
            await MainActor.run {
                switch action {
                case .create:
                    createNewWallet()
                case .recoveryOrKey:
                    importNewWallet()
                case .connect:
                    connectNewWallet()
                case .mpc:
                    activateMPCWallet()
                }
            }
        }
    }
    
    func createNewWallet() {
        guard let view = appContext.coreAppCoordinator.topVC else { return }

        UDRouter().showCreateLocalWalletScreen(createdCallback: handleWalletAddedResult, in: view)
    }
    
    func importNewWallet() {
        guard let view = appContext.coreAppCoordinator.topVC else { return }

        UDRouter().showImportVerifiedWalletScreen(walletImportedCallback: handleWalletAddedResult, in: view)
    }
    
    func connectNewWallet() {
        guard let view = appContext.coreAppCoordinator.topVC else { return }

        UDRouter().showConnectExternalWalletScreen(walletConnectedCallback: handleWalletAddedResult, in: view)
    }
 
    func handleWalletAddedResult(_ result: AddWalletNavigationController.Result) {
        switch result {
        case .cancelled, .failedToAdd:
            return
        case .created(let wallet), .createdAndBackedUp(let wallet):
            addWalletAfterAdded(wallet)
        }
    }
    
    func activateMPCWallet() {
        guard let view = appContext.coreAppCoordinator.topVC else { return }
        
        UDRouter().showActivateMPCWalletScreen(activationResultCallback: handleMPCActivationResult, in: view)
    }
    
    func handleMPCActivationResult(_ result: ActivateMPCWalletFlow.FlowResult) {
        switch result {
        case .activated(let wallet):
            addWalletAfterAdded(wallet)
        case .restart:
            Task {
                guard let view = appContext.coreAppCoordinator.topVC else { return }

                await view.presentedViewController?.dismiss(animated: true)
                activateMPCWallet()
            }
        }
    }
    
    func addWalletAfterAdded(_ wallet: UDWallet) {
        var walletName = String.Constants.wallet.localized()
        if let displayInfo = WalletDisplayInfo(wallet: wallet, domainsCount: 0, udDomainsCount: 0) {
            walletName = displayInfo.walletSourceName
        }
        appContext.toastMessageService.showToast(.walletAdded(walletName: walletName), isSticky: false)
        for profile in profiles {
            if case .wallet(let walletEntity) = profile,
               walletEntity.address == wallet.address {
                tabRouter.walletViewNavPath.append(.walletDetails(walletEntity))
                break
            }
        }
        AppReviewService.shared.appReviewEventDidOccurs(event: .walletAdded)
    }
    
    func showWalletsNumberLimitReachedPullUp() {
        Task {
            guard let view = appContext.coreAppCoordinator.topVC else { return }
            
            let walletsLimit = appContext.udWalletsService.walletsNumberLimit
            await appContext.pullUpViewService.showWalletsNumberLimitReachedPullUp(in: view,
                                                                                   maxNumberOfWallets: walletsLimit)
        }
    }
}

// MARK: - InitialAction
extension SettingsView {
    enum InitialAction {
        case none
        case importWallet, connectWallet, createNewWallet
        case showAllAddWalletOptionsPullUp, showImportWalletOptionsPullUp
    }
}

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
        SettingsView(initialAction: .none)
    }
}
