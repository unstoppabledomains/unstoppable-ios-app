//
//  PurchaseDomainsEnterDiscountCodeView.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 28.11.2023.
//

import SwiftUI

struct PurchaseDomainsEnterDiscountCodeView: View, ViewAnalyticsLogger {
    
    @Environment(\.analyticsViewName) private var analyticsViewName
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.purchaseDomainsPreferencesStorage) private var purchaseDomainsPreferencesStorage
    @State private var value: String = ""
    
    var enteredCallback: EmptyCallback?
    var analyticsName: Analytics.ViewName { analyticsViewName }

    var body: some View {
        VStack(spacing: 24) {
            Text(String.Constants.enterDiscountCode.localized())
                .font(.currentFont(size: 22, weight: .bold))
                .foregroundStyle(Color.foregroundDefault)
                .multilineTextAlignment(.center)
            UDTextFieldView(text: $value,
                            placeholder: String.Constants.discountCode.localized(),
                            focusBehaviour: .activateOnAppear)
            UDButtonView(text: String.Constants.confirm.localized(), style: .large(.raisedPrimary)) {
                logButtonPressedAnalyticEvents(button: .confirmDiscountCode, parameters: [.value: value.trimmedSpaces])
                UDVibration.buttonTap.vibrate()
                purchaseDomainsPreferencesStorage.checkoutData.discountCode = value.trimmedSpaces
                presentationMode.wrappedValue.dismiss()
                enteredCallback?()
            }
            Spacer()
        }
        .padding(EdgeInsets(top: 32, leading: 16, bottom: 16, trailing: 16))
        .onAppear {
            value = purchaseDomainsPreferencesStorage.checkoutData.discountCode
        }
    }
}

#Preview {
    PurchaseDomainsEnterDiscountCodeView()
}
