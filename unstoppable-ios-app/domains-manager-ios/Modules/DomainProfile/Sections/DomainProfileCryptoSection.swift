//
//  DomainProfileCryptoSection.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 10.10.2022.
//

import Foundation

@MainActor
final class DomainProfileCryptoSection {
    typealias SectionData = DomainProfileCryptoSectionData
    
    private var stateModel: StateModel = StateModel()

    weak var controller: DomainProfileSectionsController?
    private var recordsData: DomainRecordsData
    private let currencies: [CoinRecord]
    var state: DomainProfileViewController.State
    private var groupedRecords: [CryptoEditingGroupedRecord] = []
    private var editingGroupedRecords: [CryptoEditingGroupedRecord] = []
    private var changesCalculator = CryptoEditingGroupedRecordsChangesCalculator()
    private var isSectionExpanded = false
    private let id = UUID()
    private let sectionAnalyticName: String = "crypto"

    @MainActor
    init(sectionData: SectionData,
         state: DomainProfileViewController.State,
         controller: DomainProfileSectionsController) {
        self.recordsData = sectionData.recordsData
        self.currencies = sectionData.currencies
        self.controller = controller
        self.state = state
        let domain = controller.generalData.domain
        prepareData(domain: domain)
    }
}

// MARK: - DomainProfileSection
extension DomainProfileCryptoSection: DomainProfileSection {
    func didSelectItem(_ item: DomainProfileViewController.Item) {
        switch item {
        case .hide(let section):
            logProfileSectionButtonPressedAnalyticEvent(button: .hide,
                                                        parameters: [.section: sectionAnalyticName])
            setSectionIfCurrent(section, isExpanded: false)
        case .showAll(let section):
            logProfileSectionButtonPressedAnalyticEvent(button: .showAll,
                                                        parameters: [.section: sectionAnalyticName])
            setSectionIfCurrent(section, isExpanded: true)
        case .record(let displayInfo):
            if displayInfo.error == nil,
               !displayInfo.address.isEmpty {
                logProfileSectionButtonPressedAnalyticEvent(button: .domainRecord,
                                                            parameters: [.coin : displayInfo.coin.ticker + " (\(displayInfo.coin.version ?? ""))"])
                if displayInfo.multiChainAddressesCount == nil {
                    handleCopyAction(for: displayInfo.address, ticker: displayInfo.coin.ticker)
                } else {
                    handleCopyAction(for: displayInfo.address, ticker: displayInfo.coin.ticker + " (\(displayInfo.coin.version ?? ""))")
                }
            }
        default:
            return
        }
    }

    func fill(snapshot: inout DomainProfileSnapshot, withGeneralData generalData: DomainProfileGeneralData) {
        snapshot.appendSections([.dashesSeparator()])
        switch state {
        case .default, .updatingRecords, .loadingError, .updatingProfile, .purchaseNew:
            let records = editingGroupedRecords
            
            var missingRecords = [String]()
            for coin in Constants.nonRemovableDomainCoins {
                if let record = records.first(where: { $0.primaryRecord.coin.ticker == coin }) {
                    if record.records.first(where: { !$0.address.isEmpty }) == nil {
                        missingRecords.append(coin)
                    }
                } else {
                    missingRecords.append(coin)
                }
            }
            
            let addedCurrenciesCount = editingGroupedRecords.reduce(0, { $0 + $1.recordsWithValidAddresses.count })
            let canAddRecords = addedCurrenciesCount < currencies.count
            if !records.isEmpty {
                let section = DomainProfileViewController.Section.records(headerDescription: sectionHeader(numberOfAddedRecords: addedCurrenciesCount,
                                                                                                           isLoading: false,
                                                                                                           isButtonVisible: canAddRecords,
                                                                                                           isButtonEnabled: state == .default))
                snapshot.appendSections([section])
                let items = records.map({ record in
                    let displayInfo = displayInfo(of: record)
                    
                    let item = DomainProfileViewController.Item.record(displayInfo: displayInfo)
                    return item
                })
                let truncatedItems = truncatedItems(items,
                                                    maxItems: 3,
                                                    isExpanded: isSectionExpanded,
                                                    in: section)
                snapshot.appendItems(truncatedItems)
            }
        case .loading:
            snapshot.appendSections([.records(headerDescription: sectionHeader(numberOfAddedRecords: 0,
                                                                               isLoading: true,
                                                                               isButtonVisible: true,
                                                                               isButtonEnabled: false))])
            snapshot.appendItems([.loading(),
                                  .loading(),
                                  .loading(),
                                  .loading(style: .hideShow)])
        }
    }
    
    func areAllFieldsValid() -> Bool {
        !isAnyFieldInvalid
    }
    
    func calculateChanges() -> [DomainProfileSectionChangeDescription] {
        var changes = [DomainProfileSectionChangeDescription]()
        let changedRecordGroups = changesCalculator.calculateChangedRecordsToSaveBetween(editingGroupedRecords: editingGroupedRecords,
                                                                                         groupedRecords: groupedRecords)
        
        func createChangeFor(group: CryptoEditingGroupedRecord,
                             recordChangeTypeTransform: (CryptoRecord)->(DomainProfileSectionUIChangeType)) -> DomainProfileSectionChangeDescription {
            let uiChange = recordChangeTypeTransform(group.primaryMultiChainRecord)
            
            let dataChanges = group.records.map({ DomainProfileSectionDataChangeType.record($0) })
            let change = DomainProfileSectionChangeDescription(uiChange: uiChange,
                                                               dataChanges: dataChanges)
            
            return change
        }
        
        for group in changedRecordGroups.inserted {
            let change = createChangeFor(group: group, recordChangeTypeTransform: { .added(RecordChangeType.added($0)) })
            changes.append(change)
        }
        
        for group in changedRecordGroups.changed {
            let change = createChangeFor(group: group, recordChangeTypeTransform: { .updated(RecordChangeType.updated($0)) })
            changes.append(change)
        }
        
        for group in changedRecordGroups.removed {
            let change = createChangeFor(group: group, recordChangeTypeTransform: { .removed(RecordChangeType.removed($0)) })
            changes.append(change)
        }
        
        return changes
    }
    
    func update(sectionTypes: [DomainProfileSectionType]) {
        for sectionType in sectionTypes {
            switch sectionType {
            case .crypto(let data):
                guard self.recordsData != data.recordsData,
                      let domain = controller?.generalData.domain else { return }
                self.recordsData = data.recordsData
                prepareData(domain: domain)
                return
            default:
                continue
            }
        }
    }
    
    func apply(changes: [DomainProfileSectionChangeDescription]) {
        for change in changes {
            for dataChange in change.dataChanges {
                switch dataChange {
                case .record:
                    // All records submitted in a batch. If any record updated, we assume all records changes submitted.
                    self.groupedRecords = editingGroupedRecords
                    return
                default:
                    Void()
                }
            }
        }
    }
    
    func resetChanges() {
        editingGroupedRecords = groupedRecords
    }
}

// MARK: - Private methods
private extension DomainProfileCryptoSection {
    var isAnyFieldInvalid: Bool { editingGroupedRecords.first(where: { $0.isValidInput == false }) != nil }
    
    func sectionHeader(numberOfAddedRecords: Int,
                       isLoading: Bool,
                       isButtonVisible: Bool,
                       isButtonEnabled: Bool) -> DomainProfileSectionHeader.HeaderDescription {
        var headerButton: DomainProfileSectionHeader.HeaderButton? = nil
        if isButtonVisible {
            headerButton = .add(isEnabled: isButtonEnabled,
                                callback: { [weak self] in
                self?.logProfileSectionButtonPressedAnalyticEvent(button: .addCurrency, parameters: [:])
                self?.showAddCurrencyScreen()
            })
        }
        let secondaryTitle = numberOfAddedRecords == 0 ? "" : String(numberOfAddedRecords)
        
        return .init(title: String.Constants.domainProfileSectionRecordsName.localized(),
                     secondaryTitle: secondaryTitle,
                     button: headerButton,
                     isLoading: isLoading,
                     id: id)
    }
    
    @MainActor
    func setSectionIfCurrent(_ section: DomainProfileViewController.Section,
                             isExpanded: Bool) {
        switch section {
        case .records:
            self.isSectionExpanded = isExpanded
            controller?.viewController?.view.endEditing(true)
            controller?.sectionDidUpdate(animated: true)
        default:
            return
        }
    }
    
    func prepareData(domain: DomainDisplayInfo) {
        removePendingRecords(domain: domain)
        groupRecordsData()
        sortAndFillRecordsData()
        editingGroupedRecords = groupedRecords
    }
    
    func groupRecordsData() {
        groupedRecords = [String : [CryptoRecord]]
            .init(grouping: recordsData.records, by: { CryptoEditingGroupedRecord.getGroupIdentifierFor(coin: $0.coin) })
            .map({ (_, records) in
                return CryptoEditingGroupedRecord(records: records)
            })
        
        let groupedCurrencies = CryptoEditingGroupedRecord.groupCoins(currencies) 
        
        for (i, record) in groupedRecords.enumerated() {
            if let recordCurrencies = groupedCurrencies[CryptoEditingGroupedRecord.getGroupIdentifierFor(coin: record.primaryRecord.coin)],
               recordCurrencies.count > record.records.count {
                let missedRecords = recordCurrencies.filter({ currency in
                    record.records.first(where: { $0.coin.version == currency.version }) == nil
                }).map({ CryptoRecord(coin: $0)})
                
                if !missedRecords.isEmpty {
                    groupedRecords[i].updateRecords(record.records + missedRecords)
                }
            }
        }
    }
    
    func sortAndFillRecordsData() {
        self.groupedRecords.sort(by: { $0.primaryRecord.coin.ticker < $1.primaryRecord.coin.ticker })
        let nonRemovableCoins = Constants.nonRemovableDomainCoins
        var restRecords = groupedRecords
        var nonRemovableRecords = [CryptoEditingGroupedRecord]()
        var nonRemovableEmptyRecords = [CryptoEditingGroupedRecord]()
        
        for nonEmptyCoin in nonRemovableCoins {
            let coins = currencies.filter({ $0.ticker == nonEmptyCoin })
            guard !coins.isEmpty else {
                Debugger.printFailure("Failed to get coins for \(nonEmptyCoin)", critical: true)
                continue
            }
            
            if let i = restRecords.firstIndex(where: { $0.primaryRecord.coin.ticker == nonEmptyCoin }) {
                var record = restRecords[i]
                record.isRemovable = false
                nonRemovableRecords.append(record)
                restRecords.remove(at: i)
            } else {
                let records = coins.map({ CryptoRecord(coin: $0) })
                var newGroup = CryptoEditingGroupedRecord(records: records)
                newGroup.isRemovable = false
                nonRemovableEmptyRecords.append(newGroup)
            }
        }
        
        self.groupedRecords = nonRemovableEmptyRecords + nonRemovableRecords + restRecords
    }
    
    func displayInfo(of record: CryptoEditingGroupedRecord) -> DomainProfileViewController.ManageDomainRecordDisplayInfo {
        let actions = availableActionsFor(record: record)
        let subRecordToUse = record.primaryMultiChainRecord
        let isEnabled = state == .default || state == .updatingRecords || state == .loadingError
        var mode: DomainProfileViewController.RecordEditingMode = record.isEditing ? .editable : .viewOnly
        if record.primaryRecord.coin.isDeprecated {
            mode = record.isEditing ? .deprecatedEditing : .deprecated
        }
        let multiChainAddressesCount = record.isMultiChain ? record.validAddresses.count : nil
        
        let displayInfo = DomainProfileViewController.ManageDomainRecordDisplayInfo(coin: subRecordToUse.coin,
                                                                                    address: subRecordToUse.address,
                                                                                    multiChainAddressesCount: multiChainAddressesCount,
                                                                                    isEnabled: isEnabled,
                                                                                    error: record.addressValidationError(),
                                                                                    mode: mode,
                                                                                    availableActions: actions,
                                                                                    editingActionCallback: { [weak self] action in
            self?.didSelectEditingAction(action, for: record)
        }, dotsActionCallback: { [weak self] in
            self?.hideKeyboard()
            self?.logProfileSectionButtonPressedAnalyticEvent(button: .dots, parameters: [.coin : record.primaryRecord.coin.ticker])
        }, removeCoinCallback: { [weak self] in
            self?.handleRemoveAction(for: record)
            self?.logProfileSectionButtonPressedAnalyticEvent(button: .removeCoin, parameters: [.coin : record.primaryRecord.coin.ticker])
        })
        
        return displayInfo
    }
    
    func availableActionsFor(record: CryptoEditingGroupedRecord) -> [DomainProfileViewController.RecordAction] {
        var actions: [DomainProfileViewController.RecordAction] = []
        
        let validAddresses = record.validAddresses
        if validAddresses.isEmpty {
            return []
        } else if validAddresses.count == 1 {
            if record.isMultiChain,
               let validRecord = record.recordsWithValidAddresses.first {
                actions.append(.copy(title: nil, callback: { [weak self] in
                    self?.handleCopyMultiChainAction(for: validRecord)
                }))
            } else {
                actions.append(.copy(title: nil, callback: { [weak self] in
                    self?.logProfileSectionButtonPressedAnalyticEvent(button: .copyCoinAddress, parameters: [.coin : record.primaryRecord.coin.ticker])
                    self?.handleCopyAction(for: record)
                }))
            }
        } else if validAddresses.count > 1 {
            let addressesActions = record.recordsWithValidAddresses.map({ record in
                DomainProfileViewController.RecordAction.copy(title: record.coin.version, callback: { [weak self] in
                    self?.handleCopyMultiChainAction(for: record)
                })}
            )
            actions.append(.copyMultiple(addresses: addressesActions))
        }
        
        guard state == .default else { return actions }
        
        if record.isMultiChain {
            // For multi chain domain we allow edit address on primary screen only if only primary chain set.
            if record.recordsWithValidAddresses == [record.primaryRecord] {
                actions.append(.edit(callback: { [weak self] in
                    self?.logProfileSectionButtonPressedAnalyticEvent(button: .editCoinAddress, parameters: [.coin: record.primaryRecord.coin.ticker])
                    UDVibration.buttonTap.vibrate()
                    self?.handleEditAction(for: record)
                }))
            }
            actions.append(.editForAllChains(record.records.compactMap({ $0.coin.version }), callback: { [weak self] in
                self?.logProfileSectionButtonPressedAnalyticEvent(button: .editCoinMultiChainAddresses, parameters: [.coin: record.primaryRecord.coin.ticker])
                UDVibration.buttonTap.vibrate()
                self?.handleEditForAllChainsAction(for: record)
            }))
        } else {
            actions.append(.edit(callback: { [weak self] in
                self?.logProfileSectionButtonPressedAnalyticEvent(button: .editCoinAddress, parameters: [.coin: record.primaryRecord.coin.ticker])
                UDVibration.buttonTap.vibrate()
                self?.handleEditAction(for: record)
            }))
        }
        if record.isRemovable {
            actions.append(.remove(callback: { [weak self] in
                self?.logProfileSectionButtonPressedAnalyticEvent(button: .removeCoin, parameters: [.coin: record.primaryRecord.coin.ticker])
                UDVibration.buttonTap.vibrate()
                self?.handleRemoveAction(for: record)
            }))
        }
        
        return actions
    }
    
    func showAddCurrencyScreen() {
        Task { @MainActor in
            guard let view = self.controller?.viewController else { return }
            
            let addedCurrencies = editingGroupedRecords.reduce(into: [CoinRecord](), { $0.append(contentsOf: $1.currencies) })
            let excludedCurrencies = addedCurrencies
            
            UDRouter().showAddCurrency(from: currencies,
                                       excludedCurrencies: excludedCurrencies,
                                       addCurrencyCallback: addRecordFor(currencies:),
                                       in: view)
        }
    }
    
    func addRecordFor(currencies: [GroupedCoinRecord]) {
        Task {
            await MainActor.run {
                self.isSectionExpanded = true
                for (i, currency) in currencies.enumerated() {
                    let newRecord = CryptoEditingGroupedRecord(records: currency.coins.map({ CryptoRecord.init(coin: $0) }))
                    editingGroupedRecords.append(newRecord)
                    if i == 0 {
                        setEditingRecord(newRecord)
                    }
                }
                controller?.sectionDidUpdate(animated: true)
            }
        }
    }
    
    func setEditingRecord(_ record: CryptoEditingGroupedRecord?) {
        for i in 0..<editingGroupedRecords.count {
            let currentRecord = editingGroupedRecords[i]
            editingGroupedRecords[i].isEditing = currentRecord.primaryRecord.coin == record?.primaryRecord.coin
        }
    }
    
    func handleCopyAction(for record: CryptoEditingGroupedRecord) {
        handleCopyAction(for: record.primaryRecord.address,
                         ticker: record.primaryRecord.coin.ticker)
    }
    
    func handleCopyMultiChainAction(for record: CryptoRecord) {
        let ticker = record.coin.ticker + " (\(record.coin.version ?? ""))"
        logProfileSectionButtonPressedAnalyticEvent(button: .copyCoinAddress, parameters: [.coin : ticker])
        handleCopyAction(for: record.address,
                         ticker: ticker)
    }
    
    func handleCopyAction(for address: String, ticker: String) {
        CopyWalletAddressPullUpHandler.copyToClipboard(address: address,
                                                       ticker: ticker)
    }
    
    func handleEditAction(for record: CryptoEditingGroupedRecord) {
        setEditingRecord(record)
        controller?.sectionDidUpdate(animated: true)
        let displayInfo = displayInfo(of: record)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.controller?.viewController?.scrollToItem(.record(displayInfo: displayInfo), atPosition: .centeredVertically, animated: true)
        }
    }
    
    func handleEditForAllChainsAction(for record: CryptoEditingGroupedRecord) {
        Task {
            guard let view = self.controller?.viewController else { return }
            UDRouter().showManageMultiChainDomainAddresses(for: record.records, callback: { [weak self] updatedRecords in
                self?.handleRecordsUpdated(updatedRecords, in: record)
            }, in: view)
        }
    }
    
    func handleRecordsUpdated(_ updatedRecords: [CryptoRecord], in groupedRecord: CryptoEditingGroupedRecord) {
        guard let i = self.editingGroupedRecords.firstIndex(where: {
            CryptoEditingGroupedRecord.getGroupIdentifierFor(coin: $0.primaryRecord.coin) == CryptoEditingGroupedRecord.getGroupIdentifierFor(coin: groupedRecord.primaryRecord.coin)
        }) else { return }
        
        self.editingGroupedRecords[i].updateRecords(updatedRecords)
        controller?.sectionDidUpdate(animated: true)
    }
    
    func handleRemoveAction(for record: CryptoEditingGroupedRecord) {
        editingGroupedRecords.removeAll(where: { $0 == record })
        controller?.sectionDidUpdate(animated: true)
    }
    
    func didSelectEditingAction(_ action: DomainProfileViewController.TextEditingAction,
                                for record: CryptoEditingGroupedRecord) {
        switch action {
        case .textChanged(let address):
            guard let i = editingGroupedRecords.firstIndex(where: { $0.primaryRecord.coin == record.primaryRecord.coin }) else { return }
            
            editingGroupedRecords[i].bufferAddress = address
            editingGroupedRecords[i].resolveBufferAddress()
        case .beginEditing:
            logEditingActionAnalytics(event: .didStartEditingCoinAddress, record: record)
            handleEditAction(for: record)
        case .endEditing:
            logEditingActionAnalytics(event: .didStopEditingCoinAddress, record: record)
            userDidEndEditing()
        }
    }
    
    func logEditingActionAnalytics(event: Analytics.Event, record: CryptoEditingGroupedRecord) {
        Task {
            guard let domain = controller?.generalData.domain else { return }
            
            logAnalytic(event: event, parameters: [.domainName: domain.name,
                                                   .coin: record.primaryRecord.coin.ticker])
        }
    }
    
    func userDidEndEditing() {
        if let i = editingGroupedRecords.firstIndex(where: { $0.isEditing }) {
            editingGroupedRecords[i].resolveBufferAddress()
        }
        setEditingRecord(nil)
        controller?.sectionDidUpdate(animated: true)
    }
    
    @discardableResult
    func removePendingRecords(domain: DomainDisplayInfo) -> Bool {
        if let changes = AppGroupsBridgeService.shared.getDomainChanges().first(where: { $0.domainName == domain.name })?.changes {
            var isRemoved = false
            for change in changes {
                switch change {
                case .removed(let ticker):
                    if let i = self.recordsData.records.firstIndex(where: { $0.coin.ticker == ticker }) {
                        self.recordsData.records.remove(at: i)
                        isRemoved = true
                    }
                default:
                    Void()
                }
            }
            
            return isRemoved
        }
        return false
    }
}

// MARK: - CryptoGroupedRecord
private extension DomainProfileCryptoSection {
    struct StateModel {
        var isInitialRecordsLoaded: Bool = false
        var updateRecordsEstimatedSecondsRemaining: TimeInterval? = nil
        var didConfirmDiscardChanges: Bool = false
        var isUpdatingRecords: Bool = false
    }
}


struct DomainProfileCryptoSectionData: Equatable {
    let recordsData: DomainRecordsData
    let currencies: [CoinRecord]
}
