//
//  PurchaseDomainsCheckoutView.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 28.11.2023.
//

import SwiftUI

struct PurchaseDomainsCheckoutView: View, ViewAnalyticsLogger {
    
    @Environment(\.purchaseDomainsService) private var purchaseDomainsService
    @Environment(\.purchaseDomainsPreferencesStorage) private var purchaseDomainsPreferencesStorage
    @Environment(\.walletsDataService) private var walletsDataService
    @EnvironmentObject var stateManagerWrapper: NavigationStateManagerWrapper
    @EnvironmentObject var viewModel: PurchaseDomainsViewModel

    @State var domains: [DomainToPurchase]
    @State var selectedWallet: WalletEntity
    @State var wallets: [WalletEntity]
    @State var profileChanges: DomainProfilePendingChanges
    
    @State private var checkoutData: PurchaseDomainsCheckoutData = PurchaseDomainsCheckoutData()
    
    @State private var error: PullUpErrorConfiguration?
    @State private var pullUp: ViewPullUpConfigurationType?
    @State private var cartStatus: PurchaseDomainCartStatus = .ready(cart: .empty)
    @State private var isLoading = false
    @State private var isSelectWalletPresented = false
    @State private var isEnterZIPCodePresented = false
    @State private var isSelectDiscountsPresented = false
    @State private var isEnterDiscountCodePresented = false
    
    var analyticsName: Analytics.ViewName { .purchaseDomainsCheckout }
    var additionalAppearAnalyticParameters: Analytics.EventParameters {
        let totalPrice = domains.reduce(0, { $0 + $1.price })
        let name = domains.prefix(10).map { $0.name }.joined(separator: ",")
        return [.domainName : name,
                .count: String(domains.count),
                .price: String(totalPrice)]
    }
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                ScrollView {
                    LazyVStack(spacing: 20) {
                        mintToRowView()
                        checkoutDashSeparator()
                        usaZIPCodeView()
                        checkoutDashSeparator()
                        discountView()
                        checkoutDashSeparator()
                        summarySection()
                    }
                }
                checkoutView()
            }
            if isLoading {
                ProgressView()
            }
        }
        .allowsHitTesting(!isLoading)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(isLoading)
        .background(Color.backgroundDefault)
        .animation(.default, value: UUID())
        .onReceive(purchaseDomainsService.cartStatusPublisher.receive(on: DispatchQueue.main)) { cartStatus in
            if self.cartStatus.otherDiscountsApplied == 0 && cartStatus.otherDiscountsApplied != 0 {
                appContext.toastMessageService.showToast(.purchaseDomainsDiscountApplied(cartStatus.otherDiscountsApplied), isSticky: false)
            }
            self.cartStatus = cartStatus
            checkUpdatedCartStatus()
        }
        .onReceive(purchaseDomainsPreferencesStorage.$checkoutData.publisher.receive(on: DispatchQueue.main), perform: { checkoutData in
            self.checkoutData = checkoutData
        })
        .modifier(ShowingSelectWallet(isSelectWalletPresented: $isSelectWalletPresented,
                                      selectedWallet: selectedWallet,
                                      wallets: wallets,
                                      analyticsName: analyticsName,
                                      selectedWalletCallback: { wallet in warnUserIfNeededAndSelectWallet(wallet) }))
        .sheet(isPresented: $isEnterZIPCodePresented, content: {
            PurchaseDomainsEnterZIPCodeView()
                .passViewAnalyticsDetails(logger: self)
        })
        .sheet(isPresented: $isEnterDiscountCodePresented, content: {
            PurchaseDomainsEnterDiscountCodeView()
                .passViewAnalyticsDetails(logger: self)
        })
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Color.clear
            }
        }
        .pullUpError($error)
        .modifier(ShowingSelectDiscounts(isSelectDiscountsPresented: $isSelectDiscountsPresented))
        .viewPullUp($pullUp)
        .onAppear(perform: onAppear)
    }
}

// MARK: - Details section
private extension PurchaseDomainsCheckoutView { 
    @ViewBuilder
    func topWarningViewWith(message: TopMessageDescription, callback: @escaping MainActorCallback) -> some View {
        Button {
            Task { @MainActor in
                callback()
            }
        } label: {
            HStack(spacing: 8) {
                Image.infoIcon
                    .resizable()
                    .squareFrame(20)
                    .foregroundStyle(Color.foregroundDanger)
                AttributedText(attributesList: .init(text: message.message,
                                                     font: .currentFont(withSize: 16, weight: .medium),
                                                     textColor: .foregroundDanger,
                                                     alignment: .left),
                               updatedAttributesList: [.init(text: message.highlightedMessage,
                                                             textColor: .foregroundAccent)])
            }
            .frame(height: 48)
        }
    }
   
    @ViewBuilder
    func mintToRowView() -> some View {
        VStack(alignment: .leading) {
            HStack(spacing: 16) {
                Image(systemName: "star.fill")
                    .resizable()
                    .foregroundStyle(Color.foregroundSecondary)
                    .squareFrame(24)
                    .padding(.vertical, 10)
                HStack(spacing: 8) {
                    Text("Minting Wallet")
                        .textAttributes(color: .foregroundDefault,
                                        fontSize: 16,
                                        fontWeight: .medium)
                    Spacer()
                    selectWalletButton()
                }
            }
        }
        .padding(.horizontal, 16)
    }
    
    @ViewBuilder
    func selectWalletButton() -> some View {
        Button {
            UDVibration.buttonTap.vibrate()
            
            if !canSelectWallet,
               isFailedToAuthWallet {
                warnUserIfNeededAndSelectWallet(selectedWallet, forceReload: true)
            } else {
                logButtonPressedAnalyticEvents(button: .selectWallet)
                isSelectWalletPresented = true
            }
        } label: {
            HStack(spacing: 8) {
                Text(selectedWalletName)
                    .textAttributes(color: .foregroundSecondary,
                                    fontSize: 16)
                if let walletSelectionIndicatorImage {
                    walletSelectionIndicatorImage.resizable()
                        .squareFrame(24)
                        .foregroundStyle(Color.foregroundSecondary)
                }
            }
        }
        .buttonStyle(.plain)
        .allowsHitTesting(canSelectWallet || isFailedToAuthWallet)
    }
    
    var walletSelectionIndicatorImage: Image? {
        if case .failedToAuthoriseWallet = cartStatus {
            return .infoIcon
        }
        return canSelectWallet ? .chevronGrabberVertical : nil
    }
    
    var canSelectWallet: Bool {
        wallets.count > 1
    }
    
    var isFailedToAuthWallet: Bool {
        if case .failedToAuthoriseWallet = cartStatus {
            return true
        }
        return false
    }
    
    var selectedWalletName: String {
        selectedWallet.displayName
    }
    
    @ViewBuilder
    func usaZIPCodeView() -> some View {
        UDCollectionListRowButton(content: {
            UDListItemView(title: String.Constants.zipCode.localized(),
                           subtitle: String.Constants.toCalculateTaxes.localized(),
                           value: usaZipCodeValue,
                           imageType: .image(.usaFlagIcon),
                           imageStyle: .centred(offset: EdgeInsets(top: 6, leading: 8, bottom: 6, trailing: 8)),
                           rightViewStyle: .chevron)
            .udListItemInCollectionButtonPadding()
        }, callback: {
            logButtonPressedAnalyticEvents(button: .enterUSZIPCode)
            isEnterZIPCodePresented = true
        })
    }
    
    var usaZipCodeValue: String {
        if !checkoutData.usaZipCode.isEmpty {
            return checkoutData.usaZipCode
        } else {
            return String.Constants.usResidents.localized()
        }
    }
    
    @ViewBuilder
    func discountView() -> some View {
        UDCollectionListRowButton(content: {
            UDListItemView(title: String.Constants.creditsAndDiscounts.localized(),
                           value: discountValueString,
                           imageType: .image(.tagsCashIcon),
                           rightViewStyle: .chevron)
            .udListItemInCollectionButtonPadding()
        }, callback: {
            if cartStatus.storeCreditsAvailable == 0 && cartStatus.promoCreditsAvailable == 0 {
                logButtonPressedAnalyticEvents(button: .creditsAndDiscounts)
                isEnterDiscountCodePresented = true
            } else {
                isSelectDiscountsPresented = true
            }
        })
    }
    
    var discountValueString: String {
        if let appliedDiscountsSum {
            return "-\(formatCartPrice(appliedDiscountsSum))"
        }
        return String.Constants.apply.localized()
    }
    
    var appliedDiscountsSum: Int? {
        let sum = cartStatus.discountsAppliedSum
        
        if sum == 0 {
            return nil
        }
        
        return sum
    }
    
    @ViewBuilder
    func checkoutDashSeparator() -> some View {
        HomeExploreSeparatorView()
    }
    
}

// MARK: - Summary section
private extension PurchaseDomainsCheckoutView {
    @ViewBuilder
    func summarySection() -> some View {
        LazyVStack(alignment: .leading, spacing: 16) {
            Text(String.Constants.orderSummary.localized())
                .font(.currentFont(size: 20, weight: .bold))
                .foregroundStyle(Color.foregroundDefault)
            UDCollectionSectionBackgroundView(backgroundColor: .backgroundSubtle) {
                VStack(alignment: .center, spacing: 16) {
                    summaryDomainInfoView()
                        .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
                    additionalCheckoutDetailsView()
                        .padding(EdgeInsets(top: 0,
                                            leading: 16,
                                            bottom: shouldShowTotalDueInSummary ? 0 : 16,
                                            trailing: 16))
                    if shouldShowTotalDueInSummary {
                        checkoutDashSeparator()
                        totalDueView()
                            .padding(EdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 16))
                    }
                }
            }
        }
        .padding()
    }
    
    @ViewBuilder
    func summaryDomainInfoView() -> some View {
        LazyVStack {
            ForEach(domains) { domain in
                Text(domain.name)
            }
//            UDListItemView(title: domains.name,
//                           value: formatCartPrice(domains.price),
//                           imageType: avatarImage,
//                           imageStyle: .full)
//            .padding(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
        }
    }
    
    @ViewBuilder
    func additionalCheckoutDetailsView() -> some View {
        if hasAdditionalCheckoutData {
            VStack(spacing: 8) {
                if appliedDiscountsSum != nil {
                    additionalCheckoutDetailsRow(title: String.Constants.creditsAndDiscounts.localized(), value: discountValueString)
                }
                if cartStatus.taxes > 0 {
                    additionalCheckoutDetailsRow(title: String.Constants.taxes.localized(), value: formatCartPrice(cartStatus.taxes))
                }
            }
        }
    }
    
    var hasAdditionalCheckoutData: Bool {
        appliedDiscountsSum != nil || cartStatus.taxes > 0
    }
    
    @ViewBuilder
    func additionalCheckoutDetailsRow(title: String,
                                      value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
        }
        .font(.currentFont(size: 14))
        .foregroundStyle(Color.foregroundSecondary)
        .frame(height: 20)
    }
    
    var failedToLoadCalculations: Bool {
        if case .failedToLoadCalculations = cartStatus {
            return true
        }
        return false
    }
    
    var title: String {
        let totalDue = String.Constants.totalDue.localized()
        switch cartStatus {
        case .ready(let cart):
            let price = formatCartPrice(cart.totalPrice)
            return "\(totalDue): \(price)"
        default:
            return totalDue
        }
    }
    
    @ViewBuilder
    func totalDueView() -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(String.Constants.totalDue.localized())
                if failedToLoadCalculations {
                    HStack {
                        Image.infoIcon
                            .resizable()
                            .squareFrame(16)
                        Text(String.Constants.somethingWentWrong.localized())
                            .font(.currentFont(size: 14, weight: .medium))
                    }
                    .foregroundStyle(Color.foregroundDanger)
                }
            }
            Spacer()
            if failedToLoadCalculations {
                Button {
                    UDVibration.buttonTap.vibrate()
                    Task { try? await purchaseDomainsService.refreshCart() }
                } label: {
                    HStack {
                        Image.refreshIcon
                            .resizable()
                            .squareFrame(20)
                        Text(String.Constants.refresh.localized())
                            .font(.currentFont(size: 16, weight: .medium))
                    }
                    .foregroundStyle(Color.foregroundAccent)
                }
            } else {
                switch cartStatus {
                case .ready(let cart):
                    Text(formatCartPrice(cart.totalPrice))
                default:
                    Text("-")
                }
            }
        }
        .font(.currentFont(size: 16, weight: .medium))
        .foregroundStyle(Color.foregroundDefault)
    }
}

// MARK: - Summary section
private extension PurchaseDomainsCheckoutView {
    @ViewBuilder
    func checkoutView() -> some View {
        VStack(spacing: 0) {
            if !shouldShowTotalDueInSummary {
                totalDueView()
                    .padding(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
            }
            checkoutButton()
        }
    }
    
    var checkoutButtonTitle: String {
        if case .ready(let cart) = cartStatus,
           cart.totalPrice == 0,
           cart.appliedDiscountDetails.totalSum > 0 {
            return String.Constants.payWithCredits.localized()
        }
        return String.Constants.pay.localized()
    }
    
    var checkoutButtonIcon: Image? {
        isApplePaySupported ? .appleIcon : nil
    }
    
    var checkoutButtonStyle: UDButtonStyle {
        isApplePaySupported ? .large(.applePay) : .large(.raisedPrimary)
    }
    
    @ViewBuilder
    func checkoutButton() -> some View {
        UDButtonView(text: checkoutButtonTitle,
                     icon: checkoutButtonIcon,
                     style: checkoutButtonStyle) {
            logButtonPressedAnalyticEvents(button: .pay, parameters: [.value : String(cartStatus.totalPrice)])
            startPurchaseDomains()
        }
        .disabled(isPayButtonDisabled)
        .padding()
    }
    
    var shouldShowTotalDueInSummary: Bool {
        true
    }
    
    var isPayButtonDisabled: Bool {
        if case .ready = cartStatus {
            return false
        }
        return true
    }
}

// MARK: - Private methods
private extension PurchaseDomainsCheckoutView {
    var isApplePaySupported: Bool { purchaseDomainsService.isApplePaySupported }
    func onAppear() {
        checkoutData = purchaseDomainsPreferencesStorage.checkoutData
        warnUserIfNeededAndSelectWallet(selectedWallet, forceReload: true)
        if !isApplePaySupported {
            logAnalytic(event: .applePayNotSupported)
        }
    }
    
    func warnUserIfNeededAndSelectWallet(_ wallet: WalletEntity, forceReload: Bool = false) {
        switch wallet.displayInfo.source {
        case .external(let name, let walletMake):
            warnToSignInExternalWallet(wallet,
                                       externalWalletInfo: .init(name: name,
                                                                 icon: walletMake.icon),
                                       forceReload: forceReload)
        default:
            authorizeWithSelectedWallet(wallet, forceReload: forceReload)
        }
    }
    
    func authorizeWithSelectedWallet(_ wallet: WalletEntity, forceReload: Bool = false) {
        guard wallet.address != selectedWallet.address || isFailedToAuthWallet || forceReload else { return }
        
        error = nil
        Task {
            selectedWallet = wallet
            setLoading(true)
            do {
                try await purchaseDomainsService.authoriseWithWallet(wallet.udWallet,
                                                                     toPurchaseDomains: domains)
            } catch {
                Debugger.printFailure("Did fail to authorise wallet \(wallet.address) with error \(error)")
            }
            setLoading(false)
        }
    }
    
    func startPurchaseDomains() {
        Task {
            setLoading(true)
            do {
                let totalPrice = cartStatus.totalPrice
                let walletsToMint = try await purchaseDomainsService.getSupportedWalletsToMint()
                guard let walletToMint = walletsToMint.first(where: { $0.address == selectedWallet.address }) else {
                    throw PurchaseError.failedToGetWalletToMint
                }
                
                try await purchaseDomainsService.purchaseDomainsInTheCartAndMintTo(wallet: walletToMint)
                purchaseDomainsPreferencesStorage.checkoutData.discountCode = ""
                logAnalytic(event: .didPurchaseDomains,
                            parameters: [.value : String(totalPrice),
                                         .count: String(1),
                                         .isApplePaySupported: String(isApplePaySupported)])
                let pendingPurchasedDomains: [PendingPurchasedDomain] = domains.map { PendingPurchasedDomain(name: $0.name, walletAddress: walletToMint.address) }
                PurchasedDomainsStorage.setPurchasedDomains(pendingPurchasedDomains)
                PurchasedDomainsStorage.addPendingNonEmptyProfiles([profileChanges])
                
                await walletsDataService.didPurchaseDomains(pendingPurchasedDomains,
                                                            pendingProfiles: [profileChanges])
                Task.detached { // Run in background
                    try? await walletsDataService.refreshDataForWallet(selectedWallet)
                }
                
                viewModel.handleAction(.didPurchaseDomains)
            } catch {
                logAnalytic(event: .didFailToPurchaseDomains, parameters: [.value : String(cartStatus.totalPrice),
                                                                           .count: String(1),
                                                                           .error: error.localizedDescription])
                
                Debugger.printFailure("Did fail to purchase domains with error \(error.localizedDescription)")
                self.error = .purchaseError(tryAgainCallback: { startPurchaseDomains() })
            }
            setLoading(false)
        }
    }
    
    func setLoading(_ isLoading: Bool) {
        self.isLoading = isLoading
        stateManagerWrapper.navigationState?.navigationBackDisabled = isLoading
    }
    
    func checkUpdatedCartStatus() {
        switch cartStatus {
        case .failedToAuthoriseWallet(let wallet):
            error = .selectWalletError(wallet: wallet,
                                       canSelectWallet: canSelectWallet,
                                       selectAnotherCallback: {
                isSelectWalletPresented = true
            }, tryAgainCallback: {
                guard let wallet = self.wallets.findWithAddress(wallet.address) else { return }
                authorizeWithSelectedWallet(wallet, forceReload: true)
            })
        case .failedToLoadCalculations(let callback):
            error = .loadCalculationsError(tryAgainCallback: callback)
        default:
            return
        }
    }
    
    func warnToSignInExternalWallet(_ wallet: WalletEntity, externalWalletInfo: ExternalWalletInfo, forceReload: Bool = false) {
        pullUp = .default(.init(icon: .init(icon: externalWalletInfo.icon,
                                   size: .large),
                       title: .text(String.Constants.purchaseWalletAuthSigRequiredTitle.localized()),
                       subtitle: .label(.text(String.Constants.purchaseWalletAuthSigRequiredSubtitle.localized(externalWalletInfo.name))),
                       actionButton: .main(content: .init(title: String.Constants.gotIt.localized(),
                                                          analyticsName: .gotIt,
                                                          action: {
            pullUp = nil
            authorizeWithSelectedWallet(wallet, forceReload: forceReload)
        })),
                       dismissAble: false, 
                       analyticName: .purchaseDomainsAskToSign))
    }
    
    struct ExternalWalletInfo {
        let name: String
        let icon: UIImage
    }
    
    enum TopMessageDescription {
        case hasUnpaidDomains, applePayNotSupported
        
        var message: String {
            switch self {
            case .hasUnpaidDomains:
                return String.Constants.purchaseHasUnpaidVaultDomainsErrorMessage.localized()
            case .applePayNotSupported:
                return String.Constants.purchaseApplePayNotSupportedErrorMessage.localized()
            }
        }
        
        var highlightedMessage: String {
            switch self {
            case .hasUnpaidDomains:
                return String.Constants.purchaseHasUnpaidVaultDomainsErrorMessageHighlighted.localized()
            case .applePayNotSupported:
                return String.Constants.purchaseApplePayNotSupportedErrorMessageHighlighted.localized()
            }
        }
    }
}

// MARK: - Private methods
private extension PurchaseDomainsCheckoutView {
    struct ShowingSelectDiscounts: ViewModifier {
        @Binding var isSelectDiscountsPresented: Bool
        
        func body(content: Content) -> some View {
            content
                .sheet(isPresented: $isSelectDiscountsPresented, content: {
                    PurchaseDomainsSelectDiscountsView()
                        .presentationDetents([.medium])
                })
        }
    }
    
    struct ShowingSelectWallet: ViewModifier {
        @Binding var isSelectWalletPresented: Bool
        let selectedWallet: WalletEntity
        let wallets: [WalletEntity]
        let analyticsName: Analytics.ViewName
        let selectedWalletCallback: PurchaseDomainSelectWalletCallback
        
        func body(content: Content) -> some View {
            content
                .sheet(isPresented: $isSelectWalletPresented, content: {
                    PurchaseDomainsSelectWalletView(selectedWallet: selectedWallet,
                                                    wallets: wallets,
                                                    selectedWalletCallback: selectedWalletCallback)
                    .adaptiveSheet()
                    .environment(\.analyticsViewName, analyticsName)
                })
        }
    }
    
    enum PurchaseError: String, LocalizedError {
        case failedToGetWalletToMint
        
        public var errorDescription: String? {
            return rawValue
        }
    }
}

private extension PullUpErrorConfiguration {
    static func selectWalletError(wallet: UDWallet,
                                  canSelectWallet: Bool,
                                  selectAnotherCallback: @escaping MainActorAsyncCallback,
                                  tryAgainCallback: @escaping MainActorAsyncCallback) -> PullUpErrorConfiguration {
        let primaryAction: PullUpErrorConfiguration.ActionConfiguration
        var secondaryAction: PullUpErrorConfiguration.ActionConfiguration?
        if canSelectWallet {
            primaryAction = .init(title: String.Constants.selectAnotherWallet.localized(),
                                  callback: selectAnotherCallback, 
                                  analyticsName: .selectWallet)
            secondaryAction = .init(title: String.Constants.tryAgain.localized(),
                                    callback: tryAgainCallback,
                                    analyticsName: .tryAgain)
        } else {
            primaryAction = .init(title: String.Constants.tryAgain.localized(),
                                  callback: tryAgainCallback,
                                  analyticsName: .tryAgain)
        }
        
        return .init(title: String.Constants.purchaseWalletAuthErrorTitle.localized(wallet.address.walletAddressTruncated),
              subtitle: String.Constants.purchaseWalletAuthErrorSubtitle.localized(),
              primaryAction: primaryAction,
                     secondaryAction: secondaryAction, 
                     analyticsName: .purchaseDomainsAuthWalletError)
    }
    
    static func purchaseError(tryAgainCallback: @escaping MainActorAsyncCallback) -> PullUpErrorConfiguration {
        .init(title: String.Constants.purchaseWalletPurchaseErrorTitle.localized(),
              subtitle: String.Constants.purchaseWalletPurchaseErrorSubtitle.localized(),
              primaryAction: .init(title: String.Constants.tryAgain.localized(),
                                   callback: tryAgainCallback,
                                   analyticsName: .tryAgain), 
              analyticsName: .purchaseDomainsError)
    }
}

#Preview {
    let router = MockEntitiesFabric.Home.createHomeTabRouter()
    let viewModel = PurchaseDomainsViewModel(router: router)
    let stateWrapper = NavigationStateManagerWrapper()
    
    return NavigationStack {
        PurchaseDomainsCheckoutView(domains: [.init(name: "oleg.x",
                                                  price: 10000,
                                                  metadata: nil,
                                                  isTaken: false,
                                                  isAbleToPurchase: true)],
                                    selectedWallet: MockEntitiesFabric.Wallet.mockEntities()[0],
                                    wallets: Array(MockEntitiesFabric.Wallet.mockEntities().prefix(4)),
                                    profileChanges: .init(domainName: "oleg.x",
                                                          avatarData: UIImage.Preview.previewLandscape?.dataToUpload))
        .environment(\.purchaseDomainsService, MockFirebaseInteractionsService())
        .environmentObject(stateWrapper)
        .environmentObject(router)
        .environmentObject(viewModel)
    }
}
