//
//  AddCurrencyRecordItemView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 15.05.2024.
//

import SwiftUI

struct AddCurrencyRecordItemView: View {
    
    let record: GroupedCoinRecord
    
    @State private var currencyImageLoader: CurrencyImageLoader?
    @State private var icon: UIImage?
    private var coin: CoinRecord { record.coin }
    
    var body: some View {
        UDListItemView(title: coin.fullName ?? coin.ticker,
                       subtitle: coin.ticker,
                       imageType: .uiImage(icon ?? .init()),
                       imageStyle: .full,
                       rightViewStyle: .chevron)
            .onAppear(perform: onAppear)
    }
}

// MARK: - Private methods
private extension AddCurrencyRecordItemView {
    @MainActor
    func onAppear() {
        loadRecordIcon()
    }
    
    @MainActor
    func loadRecordIcon() {
        let currencyImageLoader = CurrencyImageLoader(currencyImageView: nil,
                                                      initialsSize: .default) { image in
            self.icon = image
        }
        self.currencyImageLoader = currencyImageLoader
        currencyImageLoader.loadImage(for: coin)
    }
}

#Preview {
    AddCurrencyRecordItemView(record: .init(coins: [MockEntitiesFabric.CoinRecords.mockRecords()[0]])!)
}
