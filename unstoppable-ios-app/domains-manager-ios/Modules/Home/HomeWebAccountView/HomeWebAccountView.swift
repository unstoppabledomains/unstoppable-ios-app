//
//  HomeWebView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 31.01.2024.
//

import SwiftUI

struct HomeWebAccountView: View, ViewAnalyticsLogger {
    
    @Environment(\.analyticsViewName) var analyticsName
    @Environment(\.analyticsAdditionalProperties) var additionalAppearAnalyticParameters
    @Environment(\.firebaseParkedDomainsService) var firebaseParkedDomainsService
    
    let user: FirebaseUser
    @EnvironmentObject var tabRouter: HomeTabRouter
    @State private var isHeaderVisible: Bool = true
    @State private var scrollOffset: CGPoint = .zero
    let navigationState: NavigationStateManager?
    @Binding var isNavTitleVisible: Bool
    @Binding var isTabBarVisible: Bool
    
    @State private var domains: [FirebaseDomainDisplayInfo] = []
    private let gridColumns = [
        GridItem(.flexible(), spacing: 32),
        GridItem(.flexible(), spacing: 32)
    ]
    private var isOtherScreenPushed: Bool { !tabRouter.walletViewNavPath.isEmpty }

    var body: some View {
        OffsetObservingListView(offset: $scrollOffset) {
            headerIconRowView()
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .onAppearanceChange($isHeaderVisible)
                .unstoppableListRowInset()
            
            headerInfoView()
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .unstoppableListRowInset()
            
            HomeWalletActionsView(actionCallback: { action in
                handleAction(action)
            }, subActionCallback: { subAction in
                handleSubAction(subAction)
            })
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 24, leading: 16, bottom: 16, trailing: 16))
            
            domainsListView()
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .unstoppableListRowInset()
        }
        .onChange(of: tabRouter.walletViewNavPath) { _ in
            updateNavTitleVisibility()
            isTabBarVisible = !isOtherScreenPushed
        }
        .onChange(of: scrollOffset) { point in
            updateNavTitleVisibility()
        }
        .listStyle(.plain)
        .clearListBackground()
        .background(Color.backgroundDefault)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(content: {
            ToolbarItem(placement: .topBarLeading) {
                HomeSettingsNavButtonView()
            }
        })
        .refreshable {
            await loadParkedDomains()
        }
        .onAppear(perform: onAppear)
    }
}

// MARK: - Private methods
private extension HomeWebAccountView {
    func onAppear() {
        setTitleViewIfNeeded()
        let firebaseDomains = firebaseParkedDomainsService.getCachedDomains()
        setFirebaseDomains(firebaseDomains)
        Task {
            await loadParkedDomains()
        }
    }
    
    func loadParkedDomains() async {
        if let firebaseDomains = (try? await firebaseParkedDomainsService.getParkedDomains()) {
            setFirebaseDomains(firebaseDomains)
        }
    }
    
    func setFirebaseDomains(_ firebaseDomains: [FirebaseDomain]) {
        self.domains = firebaseDomains.map { FirebaseDomainDisplayInfo(firebaseDomain: $0) }
    }
    
    func updateNavTitleVisibility() {
        let isNavTitleVisible = (scrollOffset.y + safeAreaInset.top > 60) || (!isHeaderVisible) &&
        !isOtherScreenPushed &&
        tabRouter.tabViewSelection == .wallets
        
        if self.isNavTitleVisible != isNavTitleVisible {
            setTitleViewIfNeeded()
            self.isNavTitleVisible = isNavTitleVisible
        }
    }
    
    func setTitleViewIfNeeded() {
        let id = user.displayName
        if navigationState?.customViewID != id {
            navigationState?.setCustomTitle(customTitle: { titleView() },
                                            id: id)
        }
    }
}

// MARK: - Private methods
private extension HomeWebAccountView {
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
    }
    
    var numberOfDomains: Int { domains.count }

    @ViewBuilder
    func headerInfoView() -> some View {
        VStack(spacing: 8) {
            Button {
                UDVibration.buttonTap.vibrate()
                tabRouter.isSelectProfilePresented = true
            } label: {
                HStack(spacing: 0) {
                    Text(user.displayName)
                        .truncationMode(.middle)
                        .font(.currentFont(size: 16, weight: .medium))
                    Image.chevronGrabberVertical
                        .squareFrame(24)
                }
                    .foregroundStyle(Color.foregroundSecondary)
                    .frame(height: 24)
            }
            Text(String.Constants.pluralNDomains.localized(numberOfDomains, numberOfDomains))
                .font(.currentFont(size: 32, weight: .bold))
                .truncationMode(.middle)
                .foregroundStyle(Color.foregroundDefault)
                .frame(height: 40)
        }
        .lineLimit(1)
        .frame(maxWidth: .infinity)
    }
    
    @ViewBuilder
    func domainsListView() -> some View {
        LazyVGrid(columns: gridColumns, spacing: 16) {
            ForEach(domains, id: \.name) { domain in
                Button {
                    logButtonPressedAnalyticEvents(button: .parkedDomainTile,
                                                   parameters: [.domainName : domain.name])
                    UDVibration.buttonTap.vibrate()
                    didSelectDomain(domain)
                } label: {
                    HomeWebAccountParkedDomainRowView(firebaseDomain: domain)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical)
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
            tabRouter.runAddWalletFlow(initialAction: .showAllAddWalletOptionsPullUp)
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
            
            appContext.firebaseParkedDomainsAuthenticationService.logOut()
            appContext.toastMessageService.showToast(.userLoggedOut, isSticky: false)
        }
    }
    
    func runDefaultMintingFlow() {
        tabRouter.runMintDomainsFlow(with: .default(email: user.email))
    }
}

// MARK: - Actions
private extension HomeWebAccountView {
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
        
        var analyticButton: Analytics.Button {
            switch self {
            case .addWallet:
                return .addWallet
            case .claim:
                return .transfer
            case .more:
                return .more
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
        
        var analyticButton: Analytics.Button {
            switch self {
            case .logOut:
                return .logOut
            }
        }
    }
}
