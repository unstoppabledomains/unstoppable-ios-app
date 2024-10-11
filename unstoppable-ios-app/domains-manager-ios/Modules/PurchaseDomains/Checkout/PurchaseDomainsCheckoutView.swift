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
    @Environment(\.userProfilesService) private var userProfilesService
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
    @State private var zipCode = ""
    @State private var isKeyboardActive = false
    @State private var isSelectWalletPresented = false
    @State private var isEnterDiscountCodePresented = false
    @State private var isShowingOrderSummary = false
    @State private var didCheckPreferredWalletToMint = false
    
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
                    LazyVStack(spacing: 0) {
                        mintToRowView()
                            .padding(.vertical, 20)
                        checkoutDashSeparator()
                        usaZIPCodeView()
                            .padding(.vertical, 20)
                        checkoutDashSeparator()
                        discountsView()
                            .padding(.vertical, 20)
                        summarySection()
                    }
                    .background(Color.backgroundDefault)
                }
                .background(scrollViewBackgroundView())
                
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
            if case .ready = cartStatus,
               !didCheckPreferredWalletToMint {
                setPreferredWalletToMint()
            }
            checkUpdatedCartStatus()
        }
        .onReceive(purchaseDomainsPreferencesStorage.$checkoutData.publisher.receive(on: DispatchQueue.main), perform: { checkoutData in
            self.checkoutData = checkoutData
        })
        .onReceive(KeyboardService.shared.keyboardOpenedPublisher.receive(on: DispatchQueue.main)) { value in
            isKeyboardActive = value
        }
        .modifier(ShowingSelectWallet(isSelectWalletPresented: $isSelectWalletPresented,
                                      selectedWallet: selectedWallet,
                                      wallets: wallets,
                                      analyticsName: analyticsName,
                                      selectedWalletCallback: { wallet in warnUserIfNeededAndSelectWallet(wallet) }))
        .sheet(isPresented: $isEnterDiscountCodePresented, content: {
            PurchaseDomainsEnterDiscountCodeView()
                .passViewAnalyticsDetails(logger: self)
                .presentationDetents([.medium])
        })
        .sheet(isPresented: $isShowingOrderSummary, content: {
            PurchaseDomainsOrderSummaryView(domains: domains,
                                            domainsUpdatedCallback: didUpdateDomainsList)
                .passViewAnalyticsDetails(logger: self)
        })
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Color.clear
            }
            ToolbarItem(placement: .keyboard) {
                if !isEnterDiscountCodePresented {
                    UDButtonView(text: String.Constants.doneButtonTitle.localized(),
                                 style: .large(.raisedPrimary)) {
                        KeyboardService.shared.hideKeyboard()
                        let zipCode = self.zipCode.trimmedSpaces
                        purchaseDomainsPreferencesStorage.checkoutData.usaZipCode = zipCode
                    }
                                 .disabled(!zipCode.isEmpty && !isValidUSStateZipCode(zipCode))
                }
            }
        }
        .trackAppearanceAnalytics(analyticsLogger: self)
        .passViewAnalyticsDetails(logger: self)
        .pullUpError($error)
        .viewPullUp($pullUp)
        .onAppear(perform: onAppear)
    }
}

// MARK: - Details section
private extension PurchaseDomainsCheckoutView {
    func didUpdateDomainsList(_ newDomains: [DomainToPurchase]) {
        guard !newDomains.isEmpty else {
            viewModel.handleAction(.didRemoveAllDomainsFromTheCart)
            return
        }
        
        self.domains = newDomains
        Task {
            setLoading(true)
            try? await purchaseDomainsService.setDomainsToPurchase(newDomains)
            setLoading(false)
        }
    }
    
    func isValidUSStateZipCode(_ zipCode: String) -> Bool {
        let numericZipCode = zipCode.replacingOccurrences(of: "-", with: "")
        
        if let zipInt = Int(numericZipCode),
           zipInt >= 501 && zipInt <= 99950 { // Valid zip code range for the entire USA is 00501 to 99950
            return true
        }
        
        return false
    }

    func setPreferredWalletToMint() {
        Task {
            do {
                let preferredWalletToMint = try? await purchaseDomainsService.getPreferredWalletToMint()
                if let preferredWalletAddress = preferredWalletToMint?.address.lowercased(),
                   selectedWallet.address != preferredWalletAddress,
                   let preferredWallet = wallets.findWithAddress(preferredWalletAddress) {
                    logAnalytic(event: .willChangeWalletToWebPreferred)
                    selectedWallet = preferredWallet
                    userProfilesService.setActiveProfile(.wallet(selectedWallet))
                }
                didCheckPreferredWalletToMint = true
            }
        }
    }
    
    @ViewBuilder
    func scrollViewBackgroundView() -> some View {
        LinearGradient(
            gradient: Gradient(stops: [
                .init(color: .backgroundDefault, location: 0.0),
                .init(color: .backgroundDefault, location: 0.5),
                .init(color: .backgroundOverlay, location: 0.5),
                .init(color: .backgroundOverlay, location: 1.0)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
   
    @ViewBuilder
    func mintToRowView() -> some View {
        VStack(alignment: .leading) {
            HStack(spacing: 16) {
                Image.walletExternalIcon
                    .resizable()
                    .foregroundStyle(Color.foregroundSecondary)
                    .squareFrame(24)
                    .padding(.vertical, 10)
                HStack(spacing: 8) {
                    Text(String.Constants.mintTo.localized())
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
                    .lineLimit(1)
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
        let displayInfo = selectedWallet.displayInfo
        let address = displayInfo.address.walletAddressTruncated
        if displayInfo.isNameSet {
            return "\(displayInfo.name) (\(address))"
        }
        return address
    }
    
    @ViewBuilder
    func usaZIPCodeView() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                Image.planetIcon20
                    .resizable()
                    .foregroundStyle(Color.foregroundSecondary)
                    .squareFrame(24)
                    .padding(.vertical, 10)
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(String.Constants.country.localized())
                            .textAttributes(color: .foregroundDefault,
                                            fontSize: 16,
                                            fontWeight: .medium)
                            .frame(height: 24)
                        Text(String.Constants.toCalculateTaxes.localized())
                            .textAttributes(color: .foregroundSecondary,
                                            fontSize: 14)
                            .frame(height: 20)
                    }
                    Spacer()
                    selectCountryPicker()
                }
            }
            
            if case .usa = checkoutData.purchaseLocation {
                UDTextFieldView(text: $zipCode,
                                placeholder: "",
                                hint: String.Constants.zipCodeForSalesTax.localized(),
                                focusBehaviour: checkoutData.usaZipCode.isEmpty ? .activateOnAppear : .default,
                                keyboardType: .numberPad)
            }
        }
        .padding(.horizontal, 16)
    }
    
    @ViewBuilder
    func selectCountryPicker() -> some View {
        UDSegmentedControlView(selection: purchaseDomainsPreferencesStorage.$checkoutData.binding.purchaseLocation,
                               items: PurchaseDomainsCheckoutData.UserPurchaseLocation.allCases)
        .frame(width: 157)
    }
    
    var usaZipCodeValue: String {
        if !checkoutData.usaZipCode.isEmpty {
            return checkoutData.usaZipCode
        } else {
            return String.Constants.usResidents.localized()
        }
    }
    
    var discountViewTitle: String {
        if appliedDiscountsSum != nil {
            return String.Constants.discountCodeApplied.localized()
        }
        return String.Constants.addDiscountCode.localized()
    }
    
    @ViewBuilder
    func discountsView() -> some View {
        VStack(spacing: 8) {
            otherDiscountsView()
            promoCreditsDiscountView()
            storeCreditsDiscountView()
        }
    }
    
    @ViewBuilder
    func otherDiscountsView() -> some View {
        Button {
            logButtonPressedAnalyticEvents(button: .creditsAndDiscounts)
            if checkoutData.discountCode.isEmpty {
                isEnterDiscountCodePresented = true
            } else {
                purchaseDomainsPreferencesStorage.checkoutData.discountCode = ""
            }
        } label: {
            otherDiscountsLabelView()
                .padding(.horizontal, 16)
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
        func otherDiscountsLabelView() -> some View {
            HStack(spacing: 16) {
                Image.tagIcon
                    .resizable()
                    .foregroundStyle(Color.foregroundSecondary)
                    .squareFrame(24)
                    .padding(.vertical, 10)
                    .rotationEffect(.degrees(-90))
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(discountViewTitle)
                            .textAttributes(color: .foregroundDefault,
                                            fontSize: 16,
                                            fontWeight: .medium)
                            .frame(height: 24)
                        if let discountCode = checkoutData.discountCodeIfEntered {
                            Text(discountCode)
                                .textAttributes(color: .foregroundSecondary,
                                                fontSize: 14)
                                .frame(height: 20)
                        }
                    }
                    Spacer()
                    
                    HStack(spacing: 8) {
                        if cartStatus.otherDiscountsApplied > 0 {
                            Text("-\(formatCartPrice(cartStatus.otherDiscountsApplied))")
                                .textAttributes(color: .foregroundSecondary,
                                                fontSize: 16)
                        }
                        discountRowTrailingIcon
                            .resizable()
                            .foregroundStyle(Color.foregroundSecondary)
                            .squareFrame(24)
                    }
                }
            }
    }
  
    
    @ViewBuilder
    func promoCreditsDiscountView() -> some View {
        if cartStatus.promoCreditsApplied > 0 {
            specificDiscountInfoRow(icon: .ticketIcon,
                                    title: String.Constants.promoCredits.localized(),
                                    value: cartStatus.promoCreditsApplied)
        }
    }
    
    @ViewBuilder
    func storeCreditsDiscountView() -> some View {
        if cartStatus.storeCreditsApplied > 0 {
            specificDiscountInfoRow(icon: .starInCloudIcon,
                                    title: String.Constants.storeCredits.localized(),
                                    value: cartStatus.storeCreditsApplied)
        }
    }
    
    @ViewBuilder
    func specificDiscountInfoRow(icon: Image,
                                 title: String,
                                 value: Int) -> some View {
        HStack(spacing: 16) {
            icon
                .resizable()
                .foregroundStyle(Color.foregroundSecondary)
                .squareFrame(24)
                .padding(.vertical, 10)

            HStack(spacing: 8) {
                Text(title)
                    .textAttributes(color: .foregroundDefault,
                                    fontSize: 16,
                                    fontWeight: .medium)
                    .frame(height: 24)
                Spacer()
                
                Text("-\(formatCartPrice(value))")
                    .textAttributes(color: .foregroundSecondary,
                                    fontSize: 16)
            }
        }
        .padding(.horizontal, 16)
        .padding(.trailing, cartStatus.otherDiscountsApplied > 0 ? 32 : 0)
    }
    
    var discountRowTrailingIcon: Image {
        if checkoutData.discountCode.isEmpty {
            return .chevronRight
        }
        return .trashIcon
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
    func checkoutDashSeparator(padding: CGFloat = 16) -> some View {
        HomeExploreSeparatorView()
            .padding(.horizontal, padding)
    }
    
}

// MARK: - Summary section
private extension PurchaseDomainsCheckoutView {
    @ViewBuilder
    func summarySection() -> some View {
        LazyVStack(alignment: .leading, spacing: 16) {
            summarySectionHeader()
            summaryDomainInfoView()
            checkoutDashSeparator(padding: 0)
            additionalCheckoutDetailsView()
            totalDueView()
        }
        .padding(16)
        .background(Color.backgroundOverlay)
        .overlay(alignment: .top, content: {
            Line()
                .stroke(Color.borderDefault, lineWidth: 1.0)
        })
    }
    
    @ViewBuilder
    func summarySectionHeader() -> some View {
        HStack {
            Text(String.Constants.orderSummary.localized() + " (\(domains.count))")
                .textAttributes(color: .foregroundDefault,
                                fontSize: 16,
                                fontWeight: .medium)
            Spacer()
            
            if !isLoading,
               case .ready = cartStatus {
                Button {
                    logButtonPressedAnalyticEvents(button: .edit)
                    UDVibration.buttonTap.vibrate()
                    isShowingOrderSummary = true
                } label: {
                    Text(String.Constants.editButtonTitle.localized())
                        .textAttributes(color: .foregroundAccent,
                                        fontSize: 16,
                                        fontWeight: .medium)
                        .underline()
                }
            }
        }
    }
    
    @ViewBuilder
    func summaryDomainInfoView() -> some View {
        LazyVStack(spacing: 16) {
            ForEach(domains) { domain in
                domainInfoRowView(domain)
            }
        }
    }
    
    @ViewBuilder
    func domainInfoRowView(_ domain: DomainToPurchase) -> some View {
        HStack(spacing: 16) {
            HStack(spacing: 16) {
                domain.tldCategory.icon
                    .squareFrame(24)
                    .foregroundStyle(Color.foregroundSecondary)
                
                HStack(spacing: 8) {
                    VStack(spacing: 0) {
                        Text(domain.name)
                            .textAttributes(color: .foregroundDefault,
                                            fontSize: 16,
                                            fontWeight: .medium)
                            .frame(height: 24)
                    }
                    Spacer()
                    Text(formatCartPrice(domain.price))
                        .textAttributes(color: .foregroundSecondary,
                                        fontSize: 16)
                }
            }
        }
        .frame(height: 44)
    }
    
    @ViewBuilder
    func additionalCheckoutDetailsView() -> some View {
        if hasAdditionalCheckoutData {
            VStack(spacing: 8) {
                additionalCheckoutDetailsRow(title: String.Constants.subtotal.localized(), value: formatCartPrice(cartStatus.subtotalPrice))
                
                if appliedDiscountsSum != nil {
                    additionalCheckoutDetailsRow(title: String.Constants.discounts.localized(), value: discountValueString)
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
                    .textAttributes(color: .foregroundDefault,
                                    fontSize: 16,
                                    fontWeight: .medium)
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
                        .textAttributes(color: .foregroundDefault,
                                        fontSize: 16,
                                        fontWeight: .medium)
                default:
                    Text("-")
                }
            }
        }
    }
}

// MARK: - Summary section
private extension PurchaseDomainsCheckoutView {
    @ViewBuilder
    func checkoutView() -> some View {
        if !isKeyboardActive {
            VStack(spacing: 0) {
                checkoutButton()
            }
            .background(Color.backgroundOverlay)
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
        zipCode = checkoutData.usaZipCode
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
                
                let purchasedData = PurchaseDomains.PurchasedDomainsData(domains: domains,
                                                                         totalSum: formatCartPrice(totalPrice),
                                                                         wallet: selectedWallet)
                
                viewModel.handleAction(.didPurchaseDomains(purchasedData))
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
}

// MARK: - Private methods
private extension PurchaseDomainsCheckoutView {
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
        PurchaseDomainsCheckoutView(domains: MockEntitiesFabric.Domains.mockDomainsToPurchase(),
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
