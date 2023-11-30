//
//  PurchaseDomainsCheckoutView.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 28.11.2023.
//

import SwiftUI

struct PurchaseDomainsCheckoutView: View {
    
    @Environment(\.purchaseDomainsService) private var purchaseDomainsService
    @Environment(\.purchaseDomainsPreferencesStorage) private var purchaseDomainsPreferencesStorage
    
    @State var domain: DomainToPurchase
    @State var selectedWallet: WalletWithInfo
    @State var wallets: [WalletWithInfo]
    
    @State private var scrollOffset: CGPoint = .zero
    @State private var cart: PurchaseDomainsCart = .empty
    @State private var checkoutData: PurchaseDomainsCheckoutData = PurchaseDomainsCheckoutData()
    
    @State private var isLoading = false
    @State private var isSelectWalletPresented = false
    @State private var isEnterZIPCodePresented = false
    @State private var isSelectDiscountsPresented = false
    @State private var isEnterDiscountCodePresented = false
    
    var purchasedCallback: EmptyCallback
    var scrollOffsetCallback: ((CGPoint)->())? = nil
    
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
        .onReceive(purchaseDomainsService.cartPublisher.receive(on: DispatchQueue.main)) { cart in
            if self.cart.discountDetails.others == 0 && cart.discountDetails.others != 0 {
                appContext.toastMessageService.showToast(.purchaseDomainsDiscountApplied(cart.discountDetails.others), isSticky: false)
            }
            self.cart = cart
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
                                      selectedWalletCallback: didSelectWallet))
        .sheet(isPresented: $isEnterZIPCodePresented, content: {
            PurchaseDomainsEnterZIPCodeView()
        })
        .sheet(isPresented: $isEnterDiscountCodePresented, content: {
            PurchaseDomainsEnterDiscountCodeView()
        })
        .modifier(ShowingSelectDiscounts(isSelectDiscountsPresented: $isSelectDiscountsPresented))
        .onAppear(perform: onAppear)
    }
}

// MARK: - Details section
private extension PurchaseDomainsCheckoutView {
    @ViewBuilder
    func headerView() -> some View {
        VStack(spacing: 16) {
            Text(String.Constants.checkout.localized())
                .titleText()
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
                           rightViewStyle: wallets.count > 1 ? .chevron : nil)
        }, callback: {
            isSelectWalletPresented = true
        })
    }
    
    var selectedWalletName: String {
        if let displayInfo = selectedWallet.displayInfo,
           displayInfo.isNameSet {
            return "\(displayInfo.name) (\(displayInfo.address.walletAddressTruncated))"
        } else {
            return selectedWallet.wallet.address.walletAddressTruncated
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
            if cart.discountDetails.storeCredits == 0 && cart.discountDetails.promoCredits == 0 {
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
        var sum = 0
        
        if checkoutData.isStoreCreditsOn {
            sum += cart.discountDetails.storeCredits
        }
        if checkoutData.isPromoCreditsOn {
            sum += cart.discountDetails.promoCredits
        }
        
        sum += cart.discountDetails.others
        
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
    
    @ViewBuilder
    func summaryDomainInfoView() -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.backgroundOverlay)
            UDListItemView(title: domain.name,
                           value: formatCartPrice(domain.price),
                           image: .tagsCashIcon)
            .padding(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
        }
    }
    
    @ViewBuilder
    func additionalCheckoutDetailsView() -> some View {
        if hasAdditionalCheckoutData {
            VStack(spacing: 8) {
                if cart.taxes > 0 {
                    additionalCheckoutDetailsRow(title: String.Constants.taxes.localized(), value: formatCartPrice(cart.taxes))
                }
                if appliedDiscountsSum != nil {
                    additionalCheckoutDetailsRow(title: String.Constants.discounts.localized(), value: discountValueString)
                }
            }
        }
    }
    
    var hasAdditionalCheckoutData: Bool {
        appliedDiscountsSum != nil || cart.taxes > 0
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
    
    @ViewBuilder
    func totalDueView() -> some View {
        HStack {
            Text(String.Constants.totalDue.localized())
            Spacer()
            Text(formatCartPrice(cart.totalPrice))
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
            purchaseDomains()
        }
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
}

// MARK: - Private methods
private extension PurchaseDomainsCheckoutView {
    func onAppear() {
        checkoutData = purchaseDomainsPreferencesStorage.checkoutData
        didSelectWallet(selectedWallet)
    }
    
    func didSelectWallet(_ wallet: WalletWithInfo) {
        Task {
            selectedWallet = wallet
            isLoading = true
            do {
                try await purchaseDomainsService.authoriseWithWallet(wallet.wallet,
                                                                     toPurchaseDomains: [domain])
            } catch {
                Debugger.printFailure("Did fail to authorise wallet \(wallet.wallet.address) with error \(error)")
            }
            isLoading = false
        }
    }
    
    func purchaseDomains() {
        purchasedCallback()
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
        let selectedWalletCallback: PurchaseDomainSelectWalletCallback
        
        func body(content: Content) -> some View {
            content
                .sheet(isPresented: $isSelectWalletPresented, content: {
                    if #available(iOS 16.0, *) {
                        PurchaseDomainsSelectWalletView(selectedWallet: selectedWallet,
                                                        wallets: wallets,
                                                        selectedWalletCallback: selectedWalletCallback)
                        .presentationDetents([.medium, .large])
                    } else {
                        PurchaseDomainsSelectWalletView(selectedWallet: selectedWallet,
                                                        wallets: wallets,
                                                        selectedWalletCallback: selectedWalletCallback)
                    }
                })
        }
    }
}

#Preview {
    PurchaseDomainsCheckoutView(domain: .init(name: "oleg.x", price: 10000, metadata: nil),
                                selectedWallet: WalletWithInfo.mock[0],
                                wallets: WalletWithInfo.mock,
                                purchasedCallback: { })
    .environment(\.purchaseDomainsService, MockFirebaseInteractionsService())
}
