//
//  PurchaseDomainsCheckoutZIPCodeView.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 28.11.2023.
//

import SwiftUI

struct PurchaseDomainsEnterZIPCodeView: View, ViewAnalyticsLogger {
    
    @Environment(\.analyticsViewName) private var analyticsViewName
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.purchaseDomainsPreferencesStorage) private var purchaseDomainsPreferencesStorage
    @State private var value: String = ""
    var analyticsName: Analytics.ViewName { analyticsViewName }

    var body: some View {
        VStack(spacing: 24) {
            Text(String.Constants.enterUSZIPCode.localized())
                .font(.currentFont(size: 22, weight: .bold))
                .foregroundStyle(Color.foregroundDefault)
                .multilineTextAlignment(.center)
            UDTextFieldView(text: $value, 
                            placeholder: String.Constants.zipCode.localized(),
                            focusBehaviour: .activateOnAppear,
                            keyboardType: .numberPad)
            UDButtonView(text: String.Constants.confirm.localized(), style: .large(.raisedPrimary)) {
                let zipCode = value.trimmedSpaces
                logButtonPressedAnalyticEvents(button: .confirmUSZIPCode, parameters: [.value: zipCode])
                UDVibration.buttonTap.vibrate()
                purchaseDomainsPreferencesStorage.checkoutData.usaZipCode = zipCode
                presentationMode.wrappedValue.dismiss()
            }
            .disabled(!value.isEmpty && !isValidUSStateZipCode(value))
            Spacer()
        }
        .padding(EdgeInsets(top: 32, leading: 16, bottom: 16, trailing: 16))
        .onAppear {
            value = purchaseDomainsPreferencesStorage.checkoutData.usaZipCode
        }
    }
}

// MARK: - Private methods
private extension PurchaseDomainsEnterZIPCodeView {
    func isValidUSStateZipCode(_ zipCode: String) -> Bool {
        let numericZipCode = zipCode.replacingOccurrences(of: "-", with: "")
        
        if let zipInt = Int(numericZipCode),
           zipInt >= 501 && zipInt <= 99950 { // Valid zip code range for the entire USA is 00501 to 99950
            return true
        }
        
        return false
    }
}

#Preview {
    PurchaseDomainsEnterZIPCodeView()
}

