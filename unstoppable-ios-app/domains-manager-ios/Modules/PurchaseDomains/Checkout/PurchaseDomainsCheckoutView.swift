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
    @Environment(\.dataAggregatorService) private var dataAggregatorService
    
    @State var domain: DomainToPurchase
    @State var selectedWallet: WalletWithInfo
    @State var wallets: [WalletWithInfo]
    @State var profileChanges: DomainProfilePendingChanges

    @State private var domainAvatar: UIImage?
    @State private var scrollOffset: CGPoint = .zero
    @State private var checkoutData: PurchaseDomainsCheckoutData = PurchaseDomainsCheckoutData()
    
    @State private var error: PullUpErrorConfiguration?
    @State private var pullUp: ViewPullUpConfiguration?
    @State private var cartStatus: PurchaseDomainCartStatus = .ready(cart: .empty)
    @State private var isLoading = false
    @State private var isSelectWalletPresented = false
    @State private var isEnterZIPCodePresented = false
    @State private var isSelectDiscountsPresented = false
    @State private var isEnterDiscountCodePresented = false
    
    var purchasedCallback: EmptyCallback
    var scrollOffsetCallback: ((CGPoint)->())? = nil
    var analyticsName: Analytics.ViewName { .purchaseDomainsCheckout }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                OffsetObservingScrollView(offset: $scrollOffset) {
                    LazyVStack {
                        headerView()
                        checkoutDashSeparator()
                        detailsSection()
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
        .onChange(of: scrollOffset) { newValue in
            scrollOffsetCallback?(newValue)
        }
        .modifier(ShowingSelectWallet(isSelectWalletPresented: $isSelectWalletPresented,
                                      selectedWallet: selectedWallet,
                                      wallets: wallets,
                                      analyticsName: analyticsName,
                                      selectedWalletCallback: { wallet in warnUserIfNeededAndSelectWallet(wallet) }))
        .sheet(isPresented: $isEnterZIPCodePresented, content: {
            PurchaseDomainsEnterZIPCodeView()
                .environment(\.analyticsViewName, analyticsName)
        })
        .sheet(isPresented: $isEnterDiscountCodePresented, content: {
            PurchaseDomainsEnterDiscountCodeView()
                .environment(\.analyticsViewName, analyticsName)
        })
        .pullUpError($error)
        .modifier(ShowingSelectDiscounts(isSelectDiscountsPresented: $isSelectDiscountsPresented))
        .viewPullUp($pullUp)
        .onAppear(perform: onAppear)
    }
}

// MARK: - Details section
private extension PurchaseDomainsCheckoutView {
    @ViewBuilder
    func headerView() -> some View {
        VStack(spacing: 32) {
            Text(String.Constants.checkout.localized())
                .titleText()
            if case .hasUnpaidDomains = cartStatus {
                Button {
                    openLinkExternally(.mainLanding)
                } label: {
                    HStack(spacing: 8) {
                        Image.infoIcon
                            .resizable()
                            .squareFrame(20)
                            .foregroundStyle(Color.foregroundDanger)
                        AttributedText(attributesList: .init(text: String.Constants.purchaseHasUnpaidVaultDomainsErrorMessage.localized(),
                                       font: .currentFont(withSize: 16, weight: .medium),
                                       textColor: .foregroundDanger,
                                       alignment: .left),
                                       updatedAttributesList: [.init(text: String.Constants.purchaseHasUnpaidVaultDomainsErrorMessageHighlighted.localized(),
                                                                     textColor: .foregroundAccent)])
                    }
                    .frame(height: 48)
                }
            }
        }
        .padding(EdgeInsets(top: 56, leading: 16, bottom: 0, trailing: 16))
    }
    
    @ViewBuilder
    func detailsSection() -> some View {
        UDCollectionSectionBackgroundView {
            VStack(alignment: .center, spacing: 0) {
                mintToRowView()
                usaZIPCodeView()
                discountView()
            }
            .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
        }
        .padding()
    }
    
    @ViewBuilder
    func mintToRowView() -> some View {
        UDCollectionListRowButton(content: {
            UDListItemView(title: String.Constants.mintTo.localized(),
                           value: selectedWalletName,
                           image: .vaultIcon,
                           rightViewStyle: walletSelectionIndicatorStyle)
        }, callback: {
            if !canSelectWallet,
                isFailedToAuthWallet {
                warnUserIfNeededAndSelectWallet(selectedWallet, forceReload: true)
            } else {
                logButtonPressedAnalyticEvents(button: .selectWallet)
                isSelectWalletPresented = true
            }
        })
        .allowsHitTesting(canSelectWallet || isFailedToAuthWallet)
    }
    
    var walletSelectionIndicatorStyle: UDListItemView.RightViewStyle? {
        if case .failedToAuthoriseWallet = cartStatus {
            return .errorCircle
        }
        return canSelectWallet ? .chevron : nil
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
        if let displayInfo = selectedWallet.displayInfo,
           displayInfo.isNameSet {
            return "\(displayInfo.name) (\(displayInfo.address.walletAddressTruncated))"
        } else {
            return selectedWallet.address.walletAddressTruncated
        }
    }
    
    @ViewBuilder
    func usaZIPCodeView() -> some View {
        UDCollectionListRowButton(content: {
            UDListItemView(title: String.Constants.zipCode.localized(),
                           subtitle: String.Constants.toCalculateTaxes.localized(),
                           value: usaZipCodeValue,
                           image: .usaFlagIcon,
                           imageStyle: .centred(offset: EdgeInsets(top: 6, leading: 8, bottom: 6, trailing: 8)),
                           rightViewStyle: .chevron)
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
                           image: .tagsCashIcon,
                           rightViewStyle: .chevron)
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
        let sum = cartStatus.otherDiscountsApplied
        
        if sum == 0 {
            return nil
        }
        
        return sum
    }
    
    @ViewBuilder
    func checkoutDashSeparator() -> some View {
        Line()
            .stroke(style: StrokeStyle(lineWidth: 1, dash: [3]))
            .foregroundColor(.black)
            .opacity(0.06)
            .frame(height: 1)
            .padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
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
    
    var avatarImage: Image {
        if let domainAvatar {
            return Image(uiImage: domainAvatar)
        }
        return .domainSharePlaceholder
    }
    
    @ViewBuilder
    func summaryDomainInfoView() -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.backgroundOverlay)
            UDListItemView(title: domain.name,
                           value: formatCartPrice(domain.price),
                           image: avatarImage,
                           imageStyle: .full)
            .padding(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
        }
    }
    
    @ViewBuilder
    func additionalCheckoutDetailsView() -> some View {
        if hasAdditionalCheckoutData {
            VStack(spacing: 8) {
                if cartStatus.taxes > 0 {
                    additionalCheckoutDetailsRow(title: String.Constants.taxes.localized(), value: formatCartPrice(cartStatus.taxes))
                }
                if appliedDiscountsSum != nil {
                    additionalCheckoutDetailsRow(title: String.Constants.creditsAndDiscounts.localized(), value: discountValueString)
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
    
    @ViewBuilder
    func checkoutButton() -> some View {
        UDButtonView(text: String.Constants.pay.localized(), icon: .appleIcon, style: .large(.applePay)) {
            logButtonPressedAnalyticEvents(button: .pay, parameters: [.value : String(cartStatus.totalPrice)])
            startPurchaseDomains()
        }
        .disabled(isPayButtonDisabled)
        .padding()
    }
    
    var shouldShowTotalDueInSummary: Bool {
        switch deviceSize {
        case .i4Inch, .i4_7Inch:
            return false
        default:
            return true
        }
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
    func onAppear() {
        checkoutData = purchaseDomainsPreferencesStorage.checkoutData
        warnUserIfNeededAndSelectWallet(selectedWallet, forceReload: true)
        Task {
            domainAvatar = await appContext.imageLoadingService.loadImage(from: .initials(domain.name, size: .default, style: .accent), downsampleDescription: nil)
        }
    }
    
    func warnUserIfNeededAndSelectWallet(_ wallet: WalletWithInfo, forceReload: Bool = false) {
        switch wallet.displayInfo?.source {
        case .external(let name, let walletMake):
            warnToSignInExternalWallet(wallet,
                                       externalWalletInfo: .init(name: name,
                                                                 icon: walletMake.icon),
                                       forceReload: forceReload)
        default:
            authorizeWithSelectedWalle(wallet, forceReload: forceReload)
        }
    }
    
    func authorizeWithSelectedWalle(_ wallet: WalletWithInfo, forceReload: Bool = false) { 
        guard wallet.address != selectedWallet.address || isFailedToAuthWallet || forceReload else { return }
        
        error = nil
        Task {
            selectedWallet = wallet
            isLoading = true
            do {
                try await purchaseDomainsService.authoriseWithWallet(wallet.wallet,
                                                                     toPurchaseDomains: [domain])
            } catch {
                Debugger.printFailure("Did fail to authorise wallet \(wallet.address) with error \(error)")
            }
            isLoading = false
        }
    }
    
    func startPurchaseDomains() {
        Task {
            isLoading = true
            do {
                let walletsToMint = try await purchaseDomainsService.getSupportedWalletsToMint()
                guard let walletToMint = walletsToMint.first(where: { $0.address == selectedWallet.address }) else {
                    throw PurchaseError.failedToGetWalletToMint
                }
                        
                try await purchaseDomainsService.purchaseDomainsInTheCartAndMintTo(wallet: walletToMint)
                purchaseDomainsPreferencesStorage.checkoutData.discountCode = ""
                logAnalytic(event: .didPurchaseDomains, parameters: [.value : String(cartStatus.totalPrice),
                                                                     .count: String(1)])
                let pendingPurchasedDomain = PendingPurchasedDomain(name: domain.name,
                                                                    walletAddress: walletToMint.address)
                PurchasedDomainsStorage.save(purchasedDomains: [pendingPurchasedDomain])
                await dataAggregatorService.aggregateData(shouldRefreshPFP: false)
                purchasedCallback()
            } catch {
                Debugger.printFailure("Did fail to purchase domains with error \(error)")
                self.error = .purchaseError(tryAgainCallback: startPurchaseDomains)
            }
            isLoading = false
        }
    }
    
    func checkUpdatedCartStatus() {
        switch cartStatus {
        case .failedToAuthoriseWallet(let wallet):
            error = .selectWalletError(wallet: wallet,
                                       canSelectWallet: canSelectWallet,
                                       selectAnotherCallback: {
                isSelectWalletPresented = true
            }, tryAgainCallback: {
                guard let walletWithInfo = self.wallets.first(where: { $0.address == wallet.address }) else { return }
                authorizeWithSelectedWalle(walletWithInfo, forceReload: true)
            })
        case .failedToLoadCalculations(let callback):
            error = .loadCalculationsError(tryAgainCallback: callback)
        default:
            return
        }
    }
    
    func warnToSignInExternalWallet(_ wallet: WalletWithInfo, externalWalletInfo: ExternalWalletInfo, forceReload: Bool = false) {
        pullUp = .init(icon: .init(icon: externalWalletInfo.icon,
                                   size: .large),
                       title: .text("Signature required"),
                       subtitle: .label(.text("You will be redirected to \(externalWalletInfo.name) to sign a message")),
                       actionButton: .main(content: .init(title: "Got it",
                                                          analyticsName: .aboutProfile,
                                                          action: {
            pullUp = nil
            authorizeWithSelectedWalle(wallet, forceReload: forceReload)
        })),
                       dismissAble: false)
    }
    
    struct ExternalWalletInfo {
        let name: String
        let icon: UIImage
    }
}

// MARK: - Private methods
private extension PurchaseDomainsCheckoutView {
    struct ShowingSelectDiscounts: ViewModifier {
        @Binding var isSelectDiscountsPresented: Bool
        
        func body(content: Content) -> some View {
            content
                .sheet(isPresented: $isSelectDiscountsPresented, content: {
                    if #available(iOS 16.0, *) {
                        PurchaseDomainsSelectDiscountsView()
                            .presentationDetents([.medium])
                    } else {
                        PurchaseDomainsSelectDiscountsView()
                    }
                })
        }
    }
    
    struct ShowingSelectWallet: ViewModifier {
        @Binding var isSelectWalletPresented: Bool
        let selectedWallet: WalletWithInfo
        let wallets: [WalletWithInfo]
        let analyticsName: Analytics.ViewName
        let selectedWalletCallback: PurchaseDomainSelectWalletCallback
        
        func body(content: Content) -> some View {
            content
                .sheet(isPresented: $isSelectWalletPresented, content: {
                    if #available(iOS 16.0, *) {
                        PurchaseDomainsSelectWalletView(selectedWallet: selectedWallet,
                                                        wallets: wallets,
                                                        selectedWalletCallback: selectedWalletCallback)
                        .presentationDetents([.medium, .large])
                        .environment(\.analyticsViewName, analyticsName)
                    } else {
                        PurchaseDomainsSelectWalletView(selectedWallet: selectedWallet,
                                                        wallets: wallets,
                                                        selectedWalletCallback: selectedWalletCallback)
                        .environment(\.analyticsViewName, analyticsName)
                    }
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
                                  selectAnotherCallback: @escaping EmptyCallback,
                                  tryAgainCallback: @escaping EmptyCallback) -> PullUpErrorConfiguration {
        let primaryAction: PullUpErrorConfiguration.ActionConfiguration
        var secondaryAction: PullUpErrorConfiguration.ActionConfiguration?
        if canSelectWallet {
            primaryAction = .init(title: String.Constants.selectAnotherWallet.localized(),
                                  callback: selectAnotherCallback)
            secondaryAction = .init(title: String.Constants.tryAgain.localized(),
                                    callback: tryAgainCallback)
        } else {
            primaryAction = .init(title: String.Constants.tryAgain.localized(),
                                  callback: tryAgainCallback)
        }
        
        return .init(title: String.Constants.purchaseWalletAuthErrorTitle.localized(wallet.address.walletAddressTruncated),
              subtitle: String.Constants.purchaseWalletAuthErrorSubtitle.localized(),
              primaryAction: primaryAction,
              secondaryAction: secondaryAction)
    }
    
    static func loadCalculationsError(tryAgainCallback: @escaping EmptyCallback) -> PullUpErrorConfiguration {
        .init(title: String.Constants.purchaseWalletCalculationsErrorTitle.localized(),
              subtitle: String.Constants.purchaseWalletCalculationsErrorSubtitle.localized(),
              primaryAction: .init(title: String.Constants.tryAgain.localized(),
                                   callback: tryAgainCallback))
    }
    
    static func purchaseError(tryAgainCallback: @escaping EmptyCallback) -> PullUpErrorConfiguration {
        .init(title: String.Constants.purchaseWalletPurchaseErrorTitle.localized(),
              subtitle: String.Constants.purchaseWalletPurchaseErrorSubtitle.localized(),
              primaryAction: .init(title: String.Constants.tryAgain.localized(),
                                   callback: tryAgainCallback))
    }
}

#Preview {
    PurchaseDomainsCheckoutView(domain: .init(name: "oleg.x", price: 10000, metadata: nil),
                                selectedWallet: WalletWithInfo.mock[0],
                                wallets: Array(WalletWithInfo.mock.prefix(4)),
                                profileChanges: .init(),
                                purchasedCallback: { })
    .environment(\.purchaseDomainsService, MockFirebaseInteractionsService())
}
