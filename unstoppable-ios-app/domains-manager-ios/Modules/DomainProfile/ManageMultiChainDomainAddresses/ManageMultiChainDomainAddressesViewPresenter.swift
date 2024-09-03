//
//  ManageMultiChainDomainAddressesViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 20.05.2022.
//

import Foundation

@MainActor
protocol ManageMultiChainDomainAddressesViewPresenterProtocol: BasePresenterProtocol {
    var record: String { get }
    func didSelectItem(_ item: ManageMultiChainDomainAddressesViewController.Item)
    func confirmButtonPressed()
    func shouldPopOnBackButton() -> Bool
}

typealias ManageMultiChainDomainAddressesCallback = ([CryptoRecord])->()

@MainActor
final class ManageMultiChainDomainAddressesViewPresenter: ViewAnalyticsLogger {
    
    private weak var view: ManageMultiChainDomainAddressesViewProtocol?
    
    private var originalRecordModel: MultiChainRecordModel
    private var editingRecordModel: MultiChainRecordModel
    private var callback: ManageMultiChainDomainAddressesCallback
    private var isChangesDiscarded = false
    var analyticsName: Analytics.ViewName { view?.analyticsName ?? .unspecified }

    init(view: ManageMultiChainDomainAddressesViewProtocol,
         records: [CryptoRecord],
         callback: @escaping ManageMultiChainDomainAddressesCallback) {
        self.view = view
        self.originalRecordModel = MultiChainRecordModel(records: records)
        self.editingRecordModel = self.originalRecordModel
        self.callback = callback
    }
}
 
// MARK: - ManageMultiChainDomainAddressesViewPresenterProtocol
extension ManageMultiChainDomainAddressesViewPresenter: ManageMultiChainDomainAddressesViewPresenterProtocol {
    var record: String { originalRecordModel.primaryRecord?.coin.ticker ?? "Unknown" }
    
    func viewDidLoad() {
        showData()
        view?.setConfirmButtonEnabled(false)
    }
    
    func didSelectItem(_ item: ManageMultiChainDomainAddressesViewController.Item) {
        switch item {
        case .topInfo:
            return
        case .record(let coin, let address, let error, _):
            if !address.isEmpty,
               error == nil {
                CopyWalletAddressPullUpHandler.copyToClipboard(address: address, ticker: coin.ticker + " (\(coin.network))")
            }
        }
    }
    
    func confirmButtonPressed() {
        view?.dismiss(animated: true, completion: { [weak self] in
            self?.callback(self?.editingRecordModel.allRecords ?? [])
        })
    }
    
    func shouldPopOnBackButton() -> Bool {
        if originalRecordModel != editingRecordModel {
            if isChangesDiscarded {
                return true 
            } else {
                guard let view = self.view else { return true }
                
                Task {
                    do {
                        try await appContext.pullUpViewService.showDiscardRecordChangesConfirmationPullUp(in: view)
                        await view.dismissPullUpMenu()
                        self.isChangesDiscarded = true
                        view.navigationController?.popViewController(animated: true)
                    }
                }
                return false                
            }
        } else {
            return true
        }
    }
}

// MARK: - Private functions
private extension ManageMultiChainDomainAddressesViewPresenter {
    func showData() {
        let records = editingRecordModel.records
        guard !records.isEmpty else {
            Debugger.printFailure("Manage multi chain screen doesn't have any record", critical: true)
            return
        }
        
        var snapshot = ManageMultiChainDomainAddressesSnapshot()
        
        snapshot.appendSections([.topInfo])
        snapshot.appendItems([.topInfo(records[0].coin)])
        
        if let primaryRecord = editingRecordModel.primaryRecord {
            snapshot.appendSections([.primaryChain])
            snapshot.appendItems([item(from: primaryRecord)])
        }
        
        snapshot.appendSections([.records])
        snapshot.appendItems(records.map({ record in
            item(from: record)
        }))
        
        view?.applySnapshot(snapshot, animated: true)
    }
    
    func item(from record: CryptoRecord) -> ManageMultiChainDomainAddressesViewController.Item {
        let error: CryptoRecord.RecordError? = record.address.isEmpty ? nil : record.validate()
        return ManageMultiChainDomainAddressesViewController.Item.record(record.coin,
                                                                         address: record.address,
                                                                         error: error) { [weak self] action in
            self?.didSelectEditingAction(action, for: record)
        }
    }
    
    func didSelectEditingAction(_ action: ManageMultiChainDomainAddressesViewController.RecordEditingAction, for record: CryptoRecord) {
        switch action {
        case .addressChanged(let address):
            editingRecordModel.changeAddress(address, for: record)
        case .beginEditing:
            logAnalytic(event: .didStartEditingCoinAddress, parameters: [.coin: analyticTickerFor(record: record)])
            let item = item(from: record)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                self?.view?.scroll(to: item)
            }
            return
        case .clearButtonPressed:
            logButtonPressedAnalyticEvents(button: .clear, parameters: [.coin: analyticTickerFor(record: record)])
            editingRecordModel.changeAddress("", for: record)
            updateConfirmButton()
            showData()
        case .endEditing:
            logAnalytic(event: .didStopEditingCoinAddress, parameters: [.coin: analyticTickerFor(record: record)])
            userDidEndEditing()
        }
    }
    
    func userDidEndEditing() {
        showData()
        updateConfirmButton()
    }
    
    func updateConfirmButton() {
        if editingRecordModel != originalRecordModel,
           editingRecordModel.validate() == nil {
            view?.setConfirmButtonEnabled(true)
        } else {
            view?.setConfirmButtonEnabled(false)
        }
    }
}

// MARK: - Private methods
private extension ManageMultiChainDomainAddressesViewPresenter {
    struct MultiChainRecordModel: Equatable {
        var primaryRecord: CryptoRecord?
        var records: [CryptoRecord]
        
        init(records: [CryptoRecord]) {
            self.records = records.filter({ !$0.coin.isPrimaryChain }).sorted(by: { $0.coin.network < $1.coin.network })
            self.primaryRecord = records.first(where: { $0.coin.isPrimaryChain })
        }
        
        mutating func changeAddress(_ address: String, for record: CryptoRecord) {
            if let i = self.records.firstIndex(where: { $0.coin.expandedTicker == record.coin.expandedTicker }) {
                self.records[i].address = address
            } else if primaryRecord?.coin.expandedTicker == record.coin.expandedTicker {
                self.primaryRecord?.address = address
            }
        }
        
        func validate() -> CryptoRecord.RecordError? {
            let nonEmptyAddressRecords = allRecords.filter({ !$0.address.isEmpty })
            if nonEmptyAddressRecords.isEmpty {
                // User didn't fill any address
                return .invalidAddress
            }
            
            let errors = nonEmptyAddressRecords.compactMap({ record -> CryptoRecord.RecordError? in
                record.validate()
            })
            
            // Some of entered addresses having issues
            return errors.first
        }
        
        var allRecords: [CryptoRecord] {
            if let primaryRecord = primaryRecord {
                return records + [primaryRecord]
            }
            return records
        }
    }
    
    func analyticTickerFor(record: CryptoRecord) -> String {
        record.coin.ticker + " (\(record.coin.network ?? ""))"
    }
}
