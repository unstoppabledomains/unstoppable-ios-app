//
//  ReverseResolutionSelectionView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.01.2024.
//

import SwiftUI

struct ReverseResolutionSelectionView: View, ViewAnalyticsLogger {
    
    @Environment(\.udWalletsService) private var udWalletsService
    @Environment(\.walletsDataService) private var walletsDataService
    @Environment(\.presentationMode) private var presentationMode

    @EnvironmentObject var tabRouter: HomeTabRouter
    @StateObject private var paymentHandler = SwiftUIViewPaymentHandler()
    var analyticsName: Analytics.ViewName { .setupReverseResolution }
    
    @State var wallet: WalletEntity
    let mode: Mode
    var domainSetCallback: (@MainActor (DomainDisplayInfo)->())? = nil
    
    enum Mode {
        case selectFirst
        case change
    }
    
    @State private var error: Error?
    @State private var isSettingRRDomain = false
    @State private var domains: [DomainDisplayInfo] = []
    @State private var selectedDomain: DomainDisplayInfo?
    @State private var scrollOffset: CGPoint = .zero
    @State private var isHeaderVisible: Bool = true
    @State private var navigationState: NavigationStateManager?
    @State private var navPath: NavigationPath = NavigationPath()
    
    var body: some View {
        NavigationViewWithCustomTitle(content: {
            VStack(spacing: 0) {
                OffsetObservingScrollView(showsIndicators: false, offset: $scrollOffset) {
                    LazyVStack(spacing: 16) {
                        headerView()
                        selectedDomainView()
                        domainsListView()
                        buyDomainView()
                    }
                }
            }
            .background(Color.backgroundDefault)
            .displayError($error, dismissCallback: dismiss)
            .safeAreaInset(edge: .bottom) {
                confirmView()
                    .background(.regularMaterial)
            }
            .toolbar(content: {
                ToolbarItem(placement: .topBarLeading) {
                    CloseButtonView {
                        
                    }
                    .opacity(0)
                }
            })
            .onAppear(perform: { setAvailableDomains() })
            .onReceive(walletsDataService.walletsPublisher.receive(on: DispatchQueue.main)) { wallets in
                switch mode {
                case .selectFirst:
                    guard let wallet = wallets.first(where: { $0.address == self.wallet.address }),
                          wallet.rrDomain == nil,
                          wallet.isReverseResolutionChangeAllowed() else {
                        dismiss()
                        return
                    }
                    self.wallet = wallet
                    setAvailableDomains()
                case .change:
                    return
                }
            }
            .onChange(of: scrollOffset) { point in
                updateNavTitleVisibility()
            }
        }, navigationStateProvider: { state in
            self.navigationState = state
            setTitleViewIfNeeded()
        }, path: $navPath)
        .trackAppearanceAnalytics(analyticsLogger: self)
    }
}

// MARK: - Private methods
private extension ReverseResolutionSelectionView {
    func setAvailableDomains() {
        switch mode {
        case .selectFirst:
            domains = wallet.domains.availableForRRItems()
        case .change:
            selectedDomain = wallet.rrDomain
            domains = wallet.domains.availableForRRItems().filter({ $0.name != selectedDomain?.name })
        }
    }
    
    func updateNavTitleVisibility() {
        let isNavTitleVisible = (scrollOffset.y > 150) || (!isHeaderVisible)
        if navigationState?.isTitleVisible != isNavTitleVisible {
            setTitleViewIfNeeded()
            withAnimation {
                navigationState?.isTitleVisible = isNavTitleVisible
            }
        }
    }
    
    func setTitleViewIfNeeded() {
        if navigationState?.customViewID == nil {
            navigationState?.setCustomTitle(customTitle: { NavigationTitleView() },
                                            id: UUID().uuidString)
        }
    }
    
    struct NavigationTitleView: View {
        var body: some View {
            HStack {
                Image.crownIcon
                    .resizable()
                    .foregroundStyle(Color.foregroundMuted)
                    .squareFrame(24)
                Text("Select primary domain")
                    .font(.currentFont(size: 16, weight: .semibold))
                    .foregroundStyle(Color.foregroundDefault)
                    .lineLimit(1)
            }
        }
    }
    
    @ViewBuilder
    func headerView() -> some View {
        VStack {
            Image.crownIcon
                .resizable()
                .squareFrame(48)
                .foregroundStyle(Color.foregroundMuted)
                .onAppearanceChange($isHeaderVisible)
            AttributedText(attributesList: .init(text: String.Constants.selectPrimaryDomainTitle.localized(wallet.displayName),
                                                 font: .currentFont(withSize: 32, weight: .bold),
                                                 textColor: .foregroundDefault,
                                                 alignment: .center),
                           width: UIScreen.main.bounds.width - 32,
                           updatedAttributesList: [.init(text: wallet.displayName,
                                                         textColor: .foregroundSecondary)])
            AttributedText(attributesList: .init(text: String.Constants.selectPrimaryDomainSubtitle.localized(wallet.address.walletAddressTruncated, wallet.displayName),
                                                 font: .currentFont(withSize: 16),
                                                 textColor: .foregroundSecondary,
                                                 alignment: .center),
                           width: UIScreen.main.bounds.width - 32,
                           updatedAttributesList: [.init(text: wallet.displayName,
                                                         font: .currentFont(withSize: 16, weight: .medium),
                                                         textColor: .foregroundDefault),
                                                   .init(text: wallet.address.walletAddressTruncated,
                                                         font: .currentFont(withSize: 16, weight: .medium),
                                                         textColor: .foregroundDefault)])
        }
        .padding()
    }
    
    
    @ViewBuilder
    func domainsSectionBackground(@ViewBuilder content: @escaping ()->some View) -> some View {
        UDCollectionSectionBackgroundView {
            content()
        }
        .padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
    }
    
    @ViewBuilder
    func selectedDomainView() -> some View {
        if case .change = mode,
           let rrDomain = wallet.rrDomain {
            domainsSectionBackground {
                domainsRowView(rrDomain)
                    .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
            }
        }
    }
    
    @ViewBuilder
    func domainsListView() -> some View {
        if !domains.isEmpty {
            domainsSectionBackground {
                LazyVStack(spacing: 0) {
                    ForEach(domains) { domain in
                        domainsRowView(domain)
                    }
                }
                .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
            }
        }
    }
    
    @ViewBuilder
    func domainsRowView(_ domain: DomainDisplayInfo) -> some View {
        UDCollectionListRowButton(content: {
            ReverseResolutionSelectionRowView(domain: domain,
                                              isSelected: domain.name == selectedDomain?.name)
        }, callback: {
            UDVibration.buttonTap.vibrate()
            selectedDomain = domain
        })
    }
    
    @ViewBuilder
    func buyDomainView() -> some View {
        UDCollectionSectionBackgroundView {
            UDCollectionListRowButton(content: {
                UDListItemView(title: String.Constants.buyNewDomain.localized(),
                               titleColor: .foregroundAccent,
                               imageType: .image(.plusIconNav),
                               imageStyle: .clearImage(foreground: .foregroundAccent))
                .padding(EdgeInsets(top: -12, leading: 0, bottom: -12, trailing: 0))
            }, callback: {
                UDVibration.buttonTap.vibrate()
                tabRouter.runPurchaseFlow()
            })
            .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
        }
        .padding(EdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 16))
    }
    
    var isConfirmButtonDisabled: Bool {
        switch mode {
        case .selectFirst:
            selectedDomain == nil
        case .change:
            selectedDomain == wallet.rrDomain
        }
    }
    
    @ViewBuilder
    func confirmView() -> some View {
        UDButtonView(text: String.Constants.confirm.localized(),
                     icon: nil,
                     style: .large(.raisedPrimary),
                     isLoading: isSettingRRDomain) {
            logButtonPressedAnalyticEvents(button: .confirm, parameters: [.value : selectedDomain?.name ?? ""])
            setSelectedDomainAsRR()
        }
                     .disabled(isConfirmButtonDisabled)
                     .padding(EdgeInsets(top: 4, leading: 16, bottom: 8, trailing: 16))
                     .allowsHitTesting(!isSettingRRDomain)
    }
    
    func setSelectedDomainAsRR() {
        Task {
            isSettingRRDomain = true
            do {
                guard let selectedDomain else { return }
                let domain = selectedDomain.toDomainItem()
                
                try await udWalletsService.setReverseResolution(to: domain,
                                                                paymentConfirmationDelegate: paymentHandler)
                dismiss()
                domainSetCallback?(selectedDomain)
            } catch {
                self.error = error
            }
            isSettingRRDomain = false
        }
    }
    
    func dismiss() {
        presentationMode.wrappedValue.dismiss()
    }
}

#Preview {
    ReverseResolutionSelectionView(wallet: MockEntitiesFabric.Wallet.mockEntities()[0], 
                                   mode: .change,
                                   domainSetCallback: nil)
}
