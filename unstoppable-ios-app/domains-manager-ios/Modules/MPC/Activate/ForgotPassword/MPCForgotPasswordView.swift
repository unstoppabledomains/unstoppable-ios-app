//
//  MPCForgotPasswordView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 02.09.2024.
//

import SwiftUI

struct MPCForgotPasswordView: View, ViewAnalyticsLogger {
    
    var analyticsName: Analytics.ViewName { .mpcForgotPassword }
    
    var body: some View {
        VStack(spacing: 32) {
            headerView()
            illustrationView()
            Spacer()
            openMailButton()
        }
        .padding(.horizontal, 16)
        .padding(.top, safeAreaInset.top)
        .padding(.bottom, safeAreaInset.bottom)
        .background(Color.backgroundDefault)
        .trackAppearanceAnalytics(analyticsLogger: self)
    }
}

// MARK: - Private methods
private extension MPCForgotPasswordView {
    var subtitleAttributesList: [AttributedText.AttributesList] {
        let subtitleHighlights = String.Constants.mpcForgotPasswordSubtitleHighlights.localized()
        let stringsToUpdate = subtitleHighlights.components(separatedBy: "\n")
        let attributesList: [AttributedText.AttributesList] = stringsToUpdate.map {
            .init(text: $0,
                  font: .currentFont(withSize: 16,
                                     weight: .medium),
                  textColor: .foregroundDefault)
        }
        
        return attributesList
    }
    
    @ViewBuilder
    func headerView() -> some View {
        VStack(spacing: 16) {
            Text(String.Constants.mpcForgotPasswordTitle.localized())
                .titleText()
            AttributedText(attributesList: .init(text: String.Constants.mpcForgotPasswordSubtitle.localized(),
                                                 font: .currentFont(withSize: 16),
                                                 textColor: .foregroundSecondary,
                                                 alignment: .center),
                           updatedAttributesList: subtitleAttributesList)
        }
        .multilineTextAlignment(.center)
    }
    
    @ViewBuilder
    func illustrationView() -> some View {
        Image.resetULWPasswordIllustration
            .resizable()
            .aspectRatio(contentMode: .fit)
            .background(Color(red: 0.14, green: 0.14, blue: 0.14).opacity(0.64))
            .padding(.horizontal, 16)
    }
    
    @ViewBuilder
    func openMailButton() -> some View {
        UDButtonView(text: String.Constants.openEmailApp.localized(),
                     style: .large(.raisedPrimary)) {
            logButtonPressedAnalyticEvents(button: .openEmailApp)
            openMailApp()
        }
    }
}

#Preview {
    NavigationStack {
        MPCForgotPasswordView()
    }
}
