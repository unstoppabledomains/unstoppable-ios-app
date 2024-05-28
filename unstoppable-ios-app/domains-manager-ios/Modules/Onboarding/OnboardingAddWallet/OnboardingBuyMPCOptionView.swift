//
//  OnboardingBuyMPCOptionView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 28.05.2024.
//

import SwiftUI

struct OnboardingBuyMPCOptionView: View {
    
    @State private var mpcWalletPrice: Int?
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            HStack(alignment: .top, spacing: 16) {
                imageView()
                VStack(alignment: .leading, spacing: 0) {
                    titleView()
                    subtitleView()
                }
            }
            Spacer()
            rightView()
        }
        .task {
            mpcWalletPrice = try? await EcomMPCPriceFetcher.shared.fetchPrice()
        }
    }
}

// MARK: - Private methods
private extension OnboardingBuyMPCOptionView {
    @ViewBuilder
    func imageView() -> some View {
        Image.shieldKeyhole
            .resizable()
            .squareFrame(20)
            .foregroundStyle(Color.white)
            .padding(EdgeInsets(10))
            .background(Color.backgroundAccentEmphasis)
            .clipShape(Circle())
            .overlay {
                Circle()
                    .stroke(Color.borderSubtle, lineWidth: 1)
            }
    }
    
    @ViewBuilder
    func titleView() -> some View {
        HStack(spacing: 8) {
            Text(String.Constants.mpcProductName.localized())
                .textAttributes(color: .foregroundDefault,
                                fontSize: 16,
                                fontWeight: .medium)
                .frame(minHeight: 24)
            popularView()
        }
    }
    
    @ViewBuilder
    func popularView() -> some View {
        Text(String.Constants.popular.localized())
            .frame(height: 20)
            .textAttributes(color: .foregroundAccent,
                            fontSize: 14,
                            fontWeight: .medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 0)
            .background(Color.backgroundAccent)
            .clipShape(Capsule())
            .overlay(
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .inset(by: 1)
                        .stroke(Color.backgroundDefault, lineWidth: 1)
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.backgroundAccent, lineWidth: 1)
                }
            )
    }
    
    @ViewBuilder
    func subtitleView() -> some View {
        VStack(alignment: .leading, spacing: 20) {
            subtitleText()
            priceView()
        }
    }
    
    @ViewBuilder
    func subtitleText() -> some View {
        Text(String.Constants.createMPCOnboardingSubtitle.localized())
            .textAttributes(color: .foregroundSecondary, fontSize: 14)
            .frame(minHeight: 20)
    }
    
    @ViewBuilder
    func priceView() -> some View {
        if let mpcWalletPrice {
            Text(String.Constants.nPricePerYear.localized(formatCartPrice(mpcWalletPrice)))
                .textAttributes(color: .foregroundDefault, fontSize: 14, fontWeight: .medium)
        } else {
            ProgressView()
        }
    }
    
    @ViewBuilder
    func rightView() -> some View {
        Image.chevronRight
            .resizable()
            .squareFrame(20)
            .foregroundStyle(Color.foregroundMuted)
    }
}

#Preview {
    OnboardingBuyMPCOptionView()
}
