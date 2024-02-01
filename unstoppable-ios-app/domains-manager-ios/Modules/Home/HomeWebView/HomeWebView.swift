//
//  HomeWebView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 31.01.2024.
//

import SwiftUI

struct HomeWebView: View {
    
    @Environment(\.firebaseParkedDomainsService) var firebaseParkedDomainsService
    
    let user: FirebaseUser
    @EnvironmentObject var tabRouter: HomeTabRouter
    @State private var isHeaderVisible: Bool = true
    @State private var isOtherScreenPresented: Bool = false
    @State private var navigationState: NavigationStateManager?
    @State private var domains: [FirebaseDomainDisplayInfo] = []
    private let gridColumns = [
        GridItem(.flexible(), spacing: 32),
        GridItem(.flexible(), spacing: 32)
    ]
    
    var body: some View {
        NavigationViewWithCustomTitle(content: {
            List {
                headerIconRowView()
                    .onAppearanceChange($isHeaderVisible)
                headerInfoView()
                HomeWalletActionsView(actionCallback: { action in
                    handleAction(action)
                }, subActionCallback: { subAction in
                    handleSubAction(subAction)
                })
                domainsListView()
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
            .onChange(of: isHeaderVisible) { newValue in
                withAnimation {
                    navigationState?.isTitleVisible =
                    !isOtherScreenPresented &&
                    !isHeaderVisible &&
                    tabRouter.tabViewSelection == .wallets
                }
            }
            .onChange(of: isOtherScreenPresented) { newValue in
                withAnimation {
                    navigationState?.isTitleVisible = !isOtherScreenPresented && !isHeaderVisible
                    tabRouter.isTabBarVisible = !isOtherScreenPresented
                }
            }
            .listStyle(.plain)
            .clearListBackground()
            .background(Color.backgroundDefault)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: HomeWalletNavigationDestination.self) { destination in
                HomeWalletLinkNavigationDestination.viewFor(navigationDestination: destination)
                    .ignoresSafeArea()
                    .onAppearanceChange($isOtherScreenPresented)
            }
            .toolbar(content: {
                ToolbarItem(placement: .topBarLeading) {
                    HomeSettingsNavButtonView()
                }
            })
            .refreshable {
                await loadParkedDomains()
            }
            .onAppear(perform: onAppear)
        }, navigationStateProvider: { state in
            self.navigationState = state
            state.customTitle = { titleView() }
        }, path: $tabRouter.walletViewNavPath)
    }
}

// MARK: - Private methods
private extension HomeWebView {
    func onAppear() {
        let firebaseDomains = firebaseParkedDomainsService.getCachedDomains()
        setFiremaseDomains(firebaseDomains)
        Task {
            await loadParkedDomains()
        }
    }
    
    func loadParkedDomains() async {
        if let firebaseDomains = (try? await firebaseParkedDomainsService.getParkedDomains()) {
            setFiremaseDomains(firebaseDomains)
        }
    }
    
    func setFiremaseDomains(_ firebaseDomains: [FirebaseDomain]) {
        print(firebaseDomains.count)
        self.domains = firebaseDomains.map { FirebaseDomainDisplayInfo(firebaseDomain: $0) }
    }
}

// MARK: - Private methods
private extension HomeWebView {
    @ViewBuilder
    func titleView() -> some View {
        HStack {
            headerIconView(size: 12)
                .squareFrame(20)
            Text(user.displayName)
                .font(.currentFont(size: 16, weight: .semibold))
                .foregroundStyle(Color.foregroundDefault)
                .lineLimit(1)
                .frame(height: 20)
        }
    }
    
    @ViewBuilder
    func headerIconView(size: CGFloat) -> some View {
        ZStack {
            Circle()
                .foregroundStyle(Color.backgroundSuccessEmphasis)
            Image.globeIcon
                .resizable()
                .squareFrame(size)
                .foregroundStyle(Color.foregroundOnEmphasis)
        }
    }
    
    @ViewBuilder
    func headerIconRowView() -> some View {
        headerIconView(size: 40)
        .squareFrame(80)
        .overlay {
            Circle()
                .stroke(lineWidth: 2)
                .foregroundStyle(Color.backgroundDefault)
        }
        .frame(maxWidth: .infinity)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }

    @ViewBuilder
    func headerInfoView() -> some View {
        VStack(spacing: 8) {
            Text(user.displayName)
                .font(.currentFont(size: 16, weight: .medium))
                .truncationMode(.middle)
                .foregroundStyle(Color.foregroundSecondary)
                .frame(height: 24)
            Text(String.Constants.pluralNDomains.localized(1, 1))
                .font(.currentFont(size: 32, weight: .bold))
                .truncationMode(.middle)
                .foregroundStyle(Color.foregroundDefault)
                .frame(height: 24)
        }
        .lineLimit(1)
        .frame(maxWidth: .infinity)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
    
    @ViewBuilder
    func domainsListView() -> some View {
        LazyVGrid(columns: gridColumns, spacing: 16) {
            ForEach(domains, id: \.name) { domain in
                Button {
                    UDVibration.buttonTap.vibrate()
                    didSelectDomain(domain)
                } label: {
                    HomeWebParkedDomainRowView(firebaseDomain: domain)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical)
    }
    
    @ViewBuilder
    func viewFor(navigationDestination: HomeWalletNavigationDestination) -> some View {
        if case .settings = navigationDestination {
            SettingsViewControllerWrapper()
                .toolbar(.hidden, for: .navigationBar)
        }
    }
    
    func didSelectDomain(_ firebaseDomain: FirebaseDomainDisplayInfo) {
        Task {
            guard let topVC = appContext.coreAppCoordinator.topVC else { return }

            let domain = DomainDisplayInfo(firebaseDomain: firebaseDomain)
            let action = await UDRouter().showDomainProfileParkedActionModule(in: topVC,
                                                                              domain: domain,
                                                                              imagesInfo: .init())
            switch action {
            case .claim:
                runDefaultMintingFlow()
            case .close:
                return
            }
        }
    }
    
    func handleAction(_ action: WebAction) {
        switch action {
        case .addWallet:
            return
        case .claim:
            runDefaultMintingFlow()
        case .more:
            return
        }
    }
    
    func handleSubAction(_ action: WebSubAction) {
        switch action {
        case .logOut:
            askUserToLogOut()
        }
    }
    
    func askUserToLogOut() {
        Task {
            guard let topVC = appContext.coreAppCoordinator.topVC else { return }
            try await appContext.pullUpViewService.showLogoutConfirmationPullUp(in: topVC)
            await topVC.dismissPullUpMenu()
            try await appContext.authentificationService.verifyWith(uiHandler: topVC, purpose: .confirm)
            
            appContext.firebaseParkedDomainsAuthenticationService.logout()
            appContext.toastMessageService.showToast(.userLoggedOut, isSticky: false)
        }
    }
    
    func runDefaultMintingFlow() {
        tabRouter.runMintDomainsFlow(with: .default(email: user.email))
    }
}

// MARK: - Actions
private extension HomeWebView {
    enum WebAction: String, CaseIterable, HomeWalletActionItem  {
        case addWallet, claim, more
        
        var title: String {
            switch self {
            case .addWallet:
                return String.Constants.addWalletTitle.localized()
            case .claim:
                return String.Constants.claimDomain.localized()
            case .more:
                return String.Constants.more.localized()
            }
        }
        
        var icon: Image {
            switch self {
            case .addWallet:
                return .plusIconNav
            case .claim:
                return .wallet3Icon
            case .more:
                return .dotsIcon
            }
        }
        
        var subActions: [WebSubAction] {
            switch self {
            case .addWallet, .claim:
                return []
            case .more:
                return [.logOut]
            }
        }
    }
    
    enum WebSubAction: String, CaseIterable, HomeWalletSubActionItem  {
        case logOut
        
        var title: String {
            switch self {
            case .logOut:
                return String.Constants.logOut.localized()
            }
        }
        
        var icon: Image {
            switch self {
            case .logOut:
                return Image(systemName: "rectangle.portrait.and.arrow.right")
            }
        }
        
        var isDestructive: Bool { true }
    }
}

#Preview {
    let user = FirebaseUser.init(email: "oleg@unstoppabledomains.com")
    let router = HomeTabRouter(accountState: .webAccount(user))

    return HomeWebView(user: user)
        .environmentObject(router)
}
