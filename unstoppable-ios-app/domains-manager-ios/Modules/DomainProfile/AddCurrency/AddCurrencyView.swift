//
//  AddCurrencyView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 15.05.2024.
//

import SwiftUI

typealias AddCurrencyCallback = ([GroupedCoinRecord])->()

struct AddCurrencyView: View {
        
    let currencies: [CoinRecord]
    let excludedCurrencies: [CoinRecord]
    let addCurrencyCallback: AddCurrencyCallback
    
    @State private var allGroupedRecords: [GroupedCoinRecord] = []
    @State private var popularRecords: [GroupedCoinRecord] = []
    @State private var otherRecords: [GroupedCoinRecord] = []
    @State private var deprecatedRecordsMap: [String : GroupedCoinRecord] = [:]
    @State private var searchKey: String = ""
    
    var body: some View {
        List {
            sectionWithRecords(popularRecords, title: String.Constants.popular.localized())
            sectionWithRecords(otherRecords, title: String.Constants.all.localized())
        }.environment(\.defaultMinListRowHeight, 28)
            .searchable(text: $searchKey, placement: .navigationBarDrawer(displayMode: .always))
            .onChange(of: searchKey, perform: { newValue in
                filterRecordsToDisplay(searchKey: newValue)
            })
        .listRowSpacing(0)
        .clearListBackground()
        .background(Color.backgroundDefault)
        .animation(.default, value: searchKey)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                CloseButtonView {
                    appContext.coreAppCoordinator.topVC?.dismiss(animated: true)
                }
            }
        }
        .onAppear(perform: onAppear)
        .navigationTitle(String.Constants.domainDetailsAddCurrency.localized())
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Private methods
private extension AddCurrencyView {
    func onAppear() {
        prepareCurrencies()
        filterRecordsToDisplay(searchKey: searchKey)
    }
    
    func prepareCurrencies() {
        let excludedCurrenciesSet = Set(excludedCurrencies.map({ CryptoEditingGroupedRecord.getGroupIdentifierFor(coin: $0) }))
        
        self.allGroupedRecords = CryptoEditingGroupedRecord.groupCoins(currencies)
            .lazy
            .compactMap({ GroupedCoinRecord(coins: $0.value) })
            .filter({ !excludedCurrenciesSet.contains(CryptoEditingGroupedRecord.getGroupIdentifierFor(coin: $0.coin)) })
            .sorted(by: { $0.coin.ticker < $1.coin.ticker })
        
        /// If both (legacy and new) coin versions is in the list, we show only non-legacy.
        /// User can select which one to add when select.
        let coinTickersToRecordsMap = [String : [GroupedCoinRecord]].init(grouping: allGroupedRecords, by: { $0.coin.ticker })
        for (ticker, records) in coinTickersToRecordsMap where records.count > 1 {
            if let deprecatedRecord = records.first(where: { $0.isDeprecated }) {
                deprecatedRecordsMap[ticker] = deprecatedRecord
                if let i = allGroupedRecords.firstIndex(of: deprecatedRecord) {
                    allGroupedRecords.remove(at: i)
                }
            }
        }
    }
    
    func filterRecordsToDisplay(searchKey: String) {
        let currencies: [GroupedCoinRecord]
        
        if searchKey.isEmpty {
            currencies = self.allGroupedRecords
        } else {
            let lowercasedKey = searchKey.lowercased()
            currencies = allGroupedRecords.filter({ isGroupedCoinRecordMatching(currency: $0, searchKey: lowercasedKey) })
        }
        
        let popularTickers = Constants.popularCoinsTickers
        var popularCurrencies = [GroupedCoinRecord]()
        var otherCurrencies = [GroupedCoinRecord]()
        
        currencies.forEach { currency in
            if popularTickers.contains(currency.coin.ticker) {
                popularCurrencies.append(currency)
            } else {
                otherCurrencies.append(currency)
            }
        }
        
        self.popularRecords = popularCurrencies
        self.otherRecords = otherCurrencies
    }
    
    func isGroupedCoinRecordMatching(currency: GroupedCoinRecord,
                                     searchKey: String) -> Bool {
        currency.coin.ticker.lowercased().contains(searchKey) ||
        currency.coin.name.lowercased().contains(searchKey) ||
        (currency.coin.fullName?.lowercased().contains(searchKey) == true)
    }
}

// MARK: - Private methods
private extension AddCurrencyView {
    @ViewBuilder
    func sectionWithRecords(_ records: [GroupedCoinRecord],
                            title: String) -> some View {
        if !records.isEmpty {
            Section {
                ForEach(records) { record in
                    selectableRecordView(record)
                        .listRowInsets(EdgeInsets(0))
                }
            } header: {
                sectionHeader(title: title)
            }
            .listRowBackground(Color.backgroundOverlay)
            .listRowSeparator(.hidden)
            .sectionSpacing(16)
        }
    }
    
    @ViewBuilder
    func sectionHeader(title: String) -> some View {
        HStack {
            Text(title)
                .font(.currentFont(size: 14, weight: .medium))
                .foregroundStyle(Color.foregroundSecondary)
            Spacer()
        }
        .offset(x: -16)
    }
    
    @ViewBuilder
    func selectableRecordView(_ record: GroupedCoinRecord) -> some View {
        UDCollectionListRowButton(content: {
            AddCurrencyRecordItemView(record: record)
            .udListItemInCollectionButtonPadding()
        }, callback: {
            didSelectRecord(record)
        })
        .padding(4)
    }
    
    func didSelectRecord(_ record: GroupedCoinRecord) {
        if let deprecatedRecord = deprecatedRecordsMap[record.coin.ticker] {
            showChooseCoinPullUp(for: record, deprecatedRecord: deprecatedRecord)
        } else {
            finishWith(coinRecords: [record])
        }
    }
    
    func showChooseCoinPullUp(for coinRecord: GroupedCoinRecord, deprecatedRecord: GroupedCoinRecord) {
        Task {
            guard let view = await appContext.coreAppCoordinator.topVC else { return }
            
            do {
                let selectionResult = try await appContext.pullUpViewService.showChooseCoinVersionPullUp(for: coinRecord.coin, in: view)
                
                switch selectionResult {
                case .both:
                    finishWith(coinRecords: [coinRecord, deprecatedRecord])
                case .multichain:
                    finishWith(coinRecords: [coinRecord])
                case .legacy:
                    finishWith(coinRecords: [deprecatedRecord])
                }
            }
        }
    }
    
    func finishWith(coinRecords: [GroupedCoinRecord]) {
        addCurrencyCallback(coinRecords)
    }
}

#Preview {
    NavigationStack {
        AddCurrencyView(currencies: MockEntitiesFabric.CoinRecords.mockRecords(),
                        excludedCurrencies: [],
                        addCurrencyCallback: { _ in })
    }
}
