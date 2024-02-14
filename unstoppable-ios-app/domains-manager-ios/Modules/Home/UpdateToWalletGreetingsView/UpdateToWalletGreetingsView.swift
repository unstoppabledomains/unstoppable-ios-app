//
//  UpdateToWalletGreetingsView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 14.02.2024.
//

import SwiftUI

struct UpdateToWalletGreetingsView: View, ViewAnalyticsLogger {
    
    @Environment(\.presentationMode) private var presentationMode
    
    var analyticsName: Analytics.ViewName { .updateToWalletGreetings }
    
    var body: some View {
        NavigationStack {
            VStack {
                ScrollView {
                    VStack {
                        VStack(spacing: 32) {
                            headerView()
                            hintsListView()
                        }
                        Spacer()
                    }
                }
                gotItButton()
            }
                .padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                .navigationTitle("")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        CloseButtonView {
                            logButtonPressedAnalyticEvents(button: .close)
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
        }
    }
}

// MARK: - Private methods
private extension UpdateToWalletGreetingsView {
    @ViewBuilder
    func headerView() -> some View {
        VStack(spacing: 24) {
            Image.udLogoBlue
                .resizable()
                .squareFrame(80)
            
            VStack(spacing: 0) {
                Text(String.Constants.updatedToWalletGreetingsTitle.localized())
                    .foregroundStyle(Color.foregroundDefault)
                Text(String.Constants.updatedToWalletGreetingsSubtitle.localized())
                    .foregroundStyle(Color.foregroundSecondary)
            }
            .font(.currentFont(size: 32, weight: .bold))
        }
    }
    
    @ViewBuilder
    func hintsListView() -> some View {
        VStack(spacing: 24) {
            ForEach(GreetingHint.allCases, id: \.self) { hint in
                hintView(for: hint)
            }
        }
    }
    
    @ViewBuilder
    func hintView(for hint: GreetingHint) -> some View {
        HStack(spacing: 16) {
            hint.icon
                .resizable()
                .squareFrame(24)
                .foregroundStyle(hint.iconTint)
                .padding(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
            VStack(alignment: .leading, spacing: 0) {
                Text(hint.title)
                    .font(.currentFont(size: 16, weight: .medium))
                    .foregroundStyle(Color.foregroundDefault)
                Text(hint.subtitle)
                    .font(.currentFont(size: 14))
                    .foregroundStyle(Color.foregroundSecondary)
            }
            Spacer()
        }
    }
    
    @ViewBuilder
    func gotItButton() -> some View {
        UDButtonView(text: String.Constants.gotIt.localized(),
                     style: .large(.raisedPrimary),
                     callback: {
            logButtonPressedAnalyticEvents(button: .gotIt)

        })
    }
}

// MARK: - Private methods
private extension UpdateToWalletGreetingsView {
    enum GreetingHint: CaseIterable {
        case wallet
        
        var icon: Image {
            switch self {
            case .wallet:
                return .appleIcon
            }
        }
        
        var iconTint: Color {
            switch self {
            case .wallet:
                return .pink
            }
        }
        
        var title: String {
            switch self {
            case .wallet:
                return "Heading"
            }
        }
        
        var subtitle: String {
            switch self {
            case .wallet:
                return "Subheading"
            }
        }
    }
}

#Preview {
    UpdateToWalletGreetingsView()
}
