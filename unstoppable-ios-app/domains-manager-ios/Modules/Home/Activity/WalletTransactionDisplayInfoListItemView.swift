//
//  WalletTransactionDisplayInfoListItemView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.03.2024.
//

import SwiftUI

struct WalletTransactionDisplayInfoListItemView: View {
    
    @Environment(\.imageLoadingService) var imageLoadingService
    
    let transaction: WalletTransactionDisplayInfo
    
    @State private var icon: UIImage?
    
    var body: some View {
        HStack(spacing: 16) {
            iconView()
            transactionTypeDetails()
            Spacer()
            transactionValueDetails()
        }
        .lineLimit(1)
        .onAppear(perform: onAppear)
    }
}

// MARK: - Private methods
private extension WalletTransactionDisplayInfoListItemView {
    func onAppear() {
        loadIcon()
    }
    
    func loadIcon() {
        Task {
            if let url = transaction.imageUrl {
                icon = await imageLoadingService.loadImage(from: .url(url, maxSize: nil),
                                                           downsampleDescription: .mid)
            }
        }
    }
}

// MARK: - Private methods
private extension WalletTransactionDisplayInfoListItemView {
    @ViewBuilder
    func iconView() -> some View {
        ZStack(alignment: .bottomTrailing) {
            iconViewForTransactionType()
            txTypeIndicatorView()
                .offset(x: 4, y: 4)
        }
    }
    
    @ViewBuilder
    func txTypeIndicatorView() -> some View {
        WalletTransactionTypeIndicatorView(type: transaction.type)
            .overlay {
                Circle()
                    .stroke(Color.backgroundDefault, lineWidth: 3)
            }
    }
    
    @ViewBuilder
    func iconViewForTransactionType() -> some View {
        switch transaction.type {
        case .tokenDeposit, .tokenWithdrawal:
            currentIcon()
                .clipShape(Circle())
        case .nftDeposit, .nftWithdrawal:
            currentIcon()
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    
    @ViewBuilder
    func currentIcon() -> some View {
        Image(uiImage: icon ?? .init())
            .resizable()
            .squareFrame(40)
    }
    
    @ViewBuilder
    func transactionTypeDetails() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(transactionTitle)
                .font(.currentFont(size: 14))
                .foregroundStyle(Color.foregroundSecondary)
                .truncationMode(.middle)
                .frame(height: 20)
            Text(sourceText)
                .font(.currentFont(size: 16, weight: .medium))
                .foregroundStyle(Color.foregroundDefault)
                .frame(height: 24)
        }
    }
    
    var transactionTitle: String {
        if transaction.type.isDeposit {
            if transaction.from.address.isEmpty {
                return String.Constants.received.localized()
            }
            return String.Constants.receivedFromN.localized(transaction.from.displayName)
        } else {
            return String.Constants.sentToN.localized(transaction.to.displayName)
        }
    }
    
    var sourceText: String {
        switch transaction.type {
        case .tokenWithdrawal, .tokenDeposit:
            return transaction.chainFullName
        case .nftDeposit, .nftWithdrawal:
            return transaction.nftName
        }
    }
    
    @ViewBuilder
    func transactionValueDetails() -> some View {
        VStack(alignment: .trailing) {
            transactionValueLabel()
                .font(.currentFont(size: 16, weight: .medium))
            gasFeeLabel()
        }
    }
    
    var transactionValue: String {
        "\(transaction.value.formatted(toMaxNumberAfterComa: 4)) \(transaction.symbol)"
    }
    
    @ViewBuilder
    func transactionValueLabel() -> some View {
        switch transaction.type {
        case .tokenDeposit:
            Text("+\(transactionValue)")
                .foregroundStyle(Color.foregroundSuccess)
        case .tokenWithdrawal:
            Text("-\(transactionValue)")
                .foregroundStyle(Color.foregroundDefault)
        case .nftDeposit, .nftWithdrawal:
            nftTxValueView()
        }
    }
    
    @ViewBuilder
    func gasFeeLabel() -> some View {
        if transaction.gas > 0 {
            Text("-\(transaction.gas.formatted(toMaxNumberAfterComa: 4)) " + String.Constants.txFee.localized())
                .font(.currentFont(size: 14))
                .foregroundStyle(Color.foregroundSecondary)
        }
    }
    
    @ViewBuilder
    func nftTxValueView() -> some View {
        if transaction.isDomainNFT {
            nftTxValueViewWith(name: String.Constants.domain.localized())
        } else {
            nftTxValueViewWith(name: String.Constants.collectible.localized())
        }
    }
    
    @ViewBuilder
    func nftTxValueViewWith(name: String) -> some View {
        Text(name)
            .font(.currentFont(size: 14, weight: .medium))
            .foregroundStyle(Color.foregroundDefault)
            .frame(height: 20)
            .padding(.horizontal, 6)
            .background(Color.backgroundMuted)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.backgroundDefault, lineWidth: 1)
            )
            .overlay(
                Capsule()
                    .inset(by: -1)
                    .stroke(Color.borderEmphasis, lineWidth: 1)
            )
            .offset(x: -1)
    }
}

#Preview {
    WalletTransactionDisplayInfoListItemView(transaction: .init(serializedTransaction: MockEntitiesFabric.WalletTxs.createMockTxOf(type: .domain, userWallet: "1", isDeposit: false), userWallet: "1"))
}
