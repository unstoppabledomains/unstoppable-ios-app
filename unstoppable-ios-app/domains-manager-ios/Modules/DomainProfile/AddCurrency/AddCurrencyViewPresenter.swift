//
//  AddCurrencyViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 18.05.2022.
//

import Foundation

protocol AddCurrencyViewPresenterProtocol: BasePresenterProtocol {
    func didSelectItem(_ item: AddCurrencyViewController.Item)
    func didSearchWith(key: String)
}

typealias AddCurrencyCallback = (GroupedCoinRecord)->()

final class AddCurrencyViewPresenter {
    
    private let currencies: [GroupedCoinRecord]
    private let coinRecordsService: CoinRecordsServiceProtocol
    private var filteredCurrencies: [GroupedCoinRecord]
    private var addCurrencyCallback: AddCurrencyCallback
    private var searchKey: String = ""
    private weak var view: AddCurrencyViewProtocol?
    
    init(view: AddCurrencyViewProtocol,
         currencies: [CoinRecord],
         excludedCurrencies: [CoinRecord],
         coinRecordsService: CoinRecordsServiceProtocol,
         addCurrencyCallback: @escaping AddCurrencyCallback) {
        self.view = view
        let excludedCurrenciesSet = Set(excludedCurrencies.map({ CryptoEditingGroupedRecord.getGroupIdentifierFor(coin: $0) }))
        
        self.currencies = CryptoEditingGroupedRecord.groupCoins(currencies)
            .lazy
            .compactMap({ GroupedCoinRecord(coins: $0.value) })
            .filter({ !excludedCurrenciesSet.contains(CryptoEditingGroupedRecord.getGroupIdentifierFor(coin: $0.coin)) })
            .sorted(by: { $0.coin.ticker < $1.coin.ticker })
        
        self.filteredCurrencies = self.currencies
        self.addCurrencyCallback = addCurrencyCallback
        self.coinRecordsService = coinRecordsService
    }
}

// MARK: - AddCurrencyViewPresenterProtocol
extension AddCurrencyViewPresenter: AddCurrencyViewPresenterProtocol {
    func viewDidLoad() {
        showCurrencies()
    }
    
    func didSelectItem(_ item: AddCurrencyViewController.Item) {
        switch item {
        case .currency(let currency):
            UDVibration.buttonTap.vibrate()
            view?.dismiss(animated: true, completion: { [weak self] in
                self?.addCurrencyCallback(currency)
            })
        case .emptyState:
            return
        }
    }
    
    func didSearchWith(key: String) {
        if key.isEmpty {
            filteredCurrencies = currencies
        } else {
            let lowercasedKey = key.lowercased()
            filteredCurrencies = currencies.filter({ currency in
                return currency.coin.ticker.lowercased().contains(lowercasedKey) || currency.coin.name.lowercased().contains(lowercasedKey) || (currency.coin.fullName?.lowercased().contains(lowercasedKey) == true)
            })            
        }
        self.searchKey = key
        showCurrencies()
    }
}

// MARK: - Private functions
private extension AddCurrencyViewPresenter {
    func showCurrencies() {
        Task {
            var snapshot = AddCurrencySnapshot()
           
            let currencies = self.filteredCurrencies
            
            if currencies.isEmpty {
                snapshot.appendSections([.empty])
                snapshot.appendItems([.emptyState])
            } else if searchKey.isEmpty {
                let popularTickers = coinRecordsService.popularCoinsTickers
                var popularCurrencies = [GroupedCoinRecord]()
                var allCurrencies = [GroupedCoinRecord]()
                
                currencies.forEach { currency in
                    if popularTickers.contains(currency.coin.ticker) {
                        popularCurrencies.append(currency)
                    } else {
                        allCurrencies.append(currency)
                    }
                }
                
                if !popularCurrencies.isEmpty {
                    snapshot.appendSections([.popular])
                    snapshot.appendItems(popularCurrencies.map({ AddCurrencyViewController.Item.currency($0) }))
                }
                
                if !allCurrencies.isEmpty {
                    snapshot.appendSections([.all])
                    snapshot.appendItems(allCurrencies.map({ AddCurrencyViewController.Item.currency($0) }))
                }
            } else {
                snapshot.appendSections([.search])
                snapshot.appendItems(currencies.map({ AddCurrencyViewController.Item.currency($0) }))
            }
            
            await view?.applySnapshot(snapshot, animated: true)
        }
    }
}
