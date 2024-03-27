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
        HStack {
            iconView()
            transactionTypeDetails()
            Spacer()
            transactionValueDetails()
        }
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
        Image(uiImage: icon ?? .appleIcon)
            .resizable()
            .squareFrame(40)
            .clipShape(Circle())
    }
    
    @ViewBuilder
    func transactionTypeDetails() -> some View {
        VStack(alignment: .leading) {
            Text(transactionTitle)
                .font(.currentFont(size: 16, weight: .medium))
                .foregroundStyle(Color.foregroundDefault)
            Text(sourceText)
                .font(.currentFont(size: 14))
                .foregroundStyle(Color.foregroundSecondary)
        }
    }
    
    var transactionTitle: String {
        switch transaction.type {
        case .tokenDeposit:
            "Received"
        case .tokenWithdrawal:
            "Sent"
        }
    }
    
    var sourceText: String {
        switch transaction.type {
        case .tokenDeposit:
            "From \(transaction.from.displayName)"
        case .tokenWithdrawal:
            "To \(transaction.to.displayName)"
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
        }
    }
    
    @ViewBuilder
    func gasFeeLabel() -> some View {
        if transaction.gas > 0 {
            Text("-\(transaction.gas.formatted(toMaxNumberAfterComa: 4)) Tx fee")
                .font(.currentFont(size: 14))
                .foregroundStyle(Color.foregroundSecondary)
        }
    }
}

#Preview {
    WalletTransactionDisplayInfoListItemView(transaction: .init(serializedTransaction: MockEntitiesFabric.WalletTxs.createMockEmptyTx(), userWallet: ""))
}
