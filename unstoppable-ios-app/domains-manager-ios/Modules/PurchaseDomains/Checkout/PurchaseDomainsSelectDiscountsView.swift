//
//  PurchaseDomainsSelectDiscountsView.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 28.11.2023.
//

import SwiftUI

struct PurchaseDomainsSelectDiscountsView: View, ViewAnalyticsLogger {
    
    @Environment(\.analyticsViewName) private var analyticsViewName
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.purchaseDomainsService) private var purchaseDomainsService
    @Environment(\.purchaseDomainsPreferencesStorage) private var purchaseDomainsPreferencesStorage
    
    @State private var isEnterDiscountCodePresented = false
    @State private var isPromoCreditsOn = false
    @State private var isStoreCreditsOn = false
    @State private var checkoutData: PurchaseDomainsCheckoutData = PurchaseDomainsCheckoutData()
    @State private var cartStatus: PurchaseDomainCartStatus = .ready(cart: .empty)
    var analyticsName: Analytics.ViewName { analyticsViewName }

    var body: some View {
        VStack(spacing: 24) {
            Text(String.Constants.applyDiscounts.localized())
                .font(.currentFont(size: 22, weight: .bold))
                .foregroundStyle(Color.foregroundDefault)
                .multilineTextAlignment(.center)
            creditsSectionView()
            discountSectionView()
            Spacer()
        }
        .padding(EdgeInsets(top: 32, leading: 16, bottom: 16, trailing: 16))
        .sheet(isPresented: $isEnterDiscountCodePresented, content: {
            PurchaseDomainsEnterDiscountCodeView(enteredCallback: {
                presentationMode.wrappedValue.dismiss()
            })
        })
        .onReceive(purchaseDomainsPreferencesStorage.$checkoutData.publisher.receive(on: DispatchQueue.main), perform: { checkoutData in
            self.checkoutData = checkoutData
        })
        .onReceive(purchaseDomainsService.cartStatusPublisher.receive(on: DispatchQueue.main)) { cartStatus in
            self.cartStatus = cartStatus
        }
        .onAppear {
            checkoutData = purchaseDomainsPreferencesStorage.checkoutData
            isPromoCreditsOn = purchaseDomainsPreferencesStorage.checkoutData.isPromoCreditsOn
            isStoreCreditsOn = purchaseDomainsPreferencesStorage.checkoutData.isStoreCreditsOn
        }
    }
}

// MARK: - Private methods
private extension PurchaseDomainsSelectDiscountsView {
    var hasPromoCredits: Bool {
        cartStatus.promoCreditsAvailable > 0
    }
    
    var hasStoreCredits: Bool {
        cartStatus.storeCreditsAvailable > 0
    }
    
    var creditsSectionHeight: CGFloat {
        var height: CGFloat = 0
        if hasPromoCredits {
            height += UDListItemView.height
        }
        if hasStoreCredits {
            height += UDListItemView.height
        }
        return height
    }
}

// MARK: -  Views
private extension PurchaseDomainsSelectDiscountsView {
    @ViewBuilder
    func creditsSectionView() -> some View {
        UDCollectionSectionBackgroundView {
            VStack(alignment: .center, spacing: 0) {
                if hasPromoCredits {
                    Toggle("\(String.Constants.promoCredits.localized()): \(formatCartPrice(cartStatus.promoCreditsAvailable))",
                           isOn: $isPromoCreditsOn)
                    .toggleStyle(UDToggleStyle())
                    .frame(minHeight: UDListItemView.height)
                    .onChange(of: isPromoCreditsOn) { newValue in
                        logButtonPressedAnalyticEvents(button: .applyPromoCredits, parameters: [.value : String(newValue)])
                        purchaseDomainsPreferencesStorage.checkoutData.isPromoCreditsOn = newValue
                    }
                }
                if hasStoreCredits {
                    Toggle("\(String.Constants.storeCredits.localized()): \(formatCartPrice(cartStatus.storeCreditsAvailable))",
                           isOn: $isStoreCreditsOn)
                    .toggleStyle(UDToggleStyle())
                    .frame(minHeight: UDListItemView.height)
                    .onChange(of: isStoreCreditsOn) { newValue in
                        logButtonPressedAnalyticEvents(button: .applyStoreCredits, parameters: [.value : String(newValue)])
                        purchaseDomainsPreferencesStorage.checkoutData.isStoreCreditsOn = newValue
                    }
                }
            }
            .font(.currentFont(size: 16, weight: .medium))
            .padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
        }
        .frame(height: creditsSectionHeight)
    }
    
    @ViewBuilder
    func discountSectionView() -> some View {
        UDCollectionSectionBackgroundView {
            if checkoutData.discountCode.isEmpty {
                addDiscountRow()
            } else {
                discountAppliedRow()
            }
        }
        .frame(height: UDListItemView.height)
    }
    
    @ViewBuilder
    func addDiscountRow() -> some View {
        Button {
            logButtonPressedAnalyticEvents(button: .creditsAndDiscounts)
            UDVibration.buttonTap.vibrate()
            isEnterDiscountCodePresented = true
        } label: {
            HStack(spacing: 16) {
                Image.tagIcon
                    .resizable()
                    .squareFrame(20)
                Text(String.Constants.addDiscountCode.localized())
                    .font(.currentFont(size: 16, weight: .medium))
                Spacer()
            }
        }
        .padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
    }
    
    @ViewBuilder
    func discountAppliedRow() -> some View {
        Button {
            logButtonPressedAnalyticEvents(button: .removeDiscountCode)
            UDVibration.buttonTap.vibrate()
            purchaseDomainsPreferencesStorage.checkoutData.discountCode = ""
        } label: {
            HStack(spacing: 4) {
                Text("\(String.Constants.discountCode.localized()): \(formatCartPrice(cartStatus.otherDiscountsApplied))")
                    .foregroundStyle(Color.foregroundDefault)
                Spacer()
                HStack(spacing: 8) {
                    Text(purchaseDomainsPreferencesStorage.checkoutData.discountCode)
                    Image.cancelIcon
                        .resizable()
                        .squareFrame(20)
                }
                .foregroundStyle(Color.foregroundSecondary)
            }
            .font(.currentFont(size: 16, weight: .medium))
            
        }
        .padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
    }
}

#Preview {
    PurchaseDomainsSelectDiscountsView()
        .environment(\.purchaseDomainsService, MockFirebaseInteractionsService())

}




