//
//  SelectAndClaimFlowStep.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 13.11.2020.
//

import UIKit

struct DomainEntry {
    let name: String
    let hasCredit: Bool
}

class SelectAndClaimFlowStep: SecureSelectionFlowStep {

    @IBOutlet weak var activeWalletView: ActiveWalletView!
    @IBOutlet weak var walletViewHeight: NSLayoutConstraint!
    
    @IBOutlet weak var youCanClaimTitle: UILabel!
    @IBOutlet weak var claimSelectedButton: UIButton!
    @IBOutlet weak var claimToCustomButton: UIButton!
    @IBOutlet weak var selectAllButton: UIButton!
    
    @IBOutlet weak var domainsTableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var wallets: [UDWallet] = []
    var activeWallet: UDWallet?
    var domainEntries: [DomainEntry] = []
    
    var mintingLimit: Int? {
        selectionViewController?.mintingHostDataController?.mintingLimit
    }
    
    var selectedRows: [Int] {
        let selectedPaths = self.domainsTableView.indexPathsForSelectedRows ?? []
        return selectedPaths.map { $0.row }
    }
    
    override func didMoveToSuperview() {
        if self.activeWallet != nil {
            self.updateWalletsUI(wallets: wallets, activeWallet: activeWallet)
            triggerUpperWalletView(animated: false)
        }
    }

    @IBAction func didTapActiveWalletView(_ sender: UITapGestureRecognizer) {
        guard let c = selectionViewController?.controller as? DomainsSelectionController else {
            fatalError()
        }
        var controller = c
        
        controller.requestSelectActiveWallet(activeWallet) {
            wallets, activeWallet in
            self.updateWalletsUI(wallets: wallets, activeWallet: activeWallet)
            DispatchQueue.main.async { [weak self] in
                self?.domainsTableView.reloadData()
                self?.updateMintSelectedButton()
            }
        }
    }
    
    @IBAction func didTapClaimSelectedButton(_ sender: UIButton) {
        guard let viewController = selectionViewController else { return }
        
        AuthentificationService.instance.verifyWith(uiHandler: viewController, purpose: .confirm, completionCallback: self.proceedWithSelectedDomains(), cancellationCallback: nil)
    }
    
    private func proceedWithSelectedDomains() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard self.selectedRows.count > 0 else {
                Debugger.printFailure("No domains selected")
                return
            }
            let selectedEntries = self.selectedRows.map( {self.domainEntries[$0]} )
            let newDomains = selectedEntries.map( { DomainItem(name: $0.name, status: .unclaimed)} )
            let paidDomains = selectedEntries
                                        .filter({!$0.hasCredit})
                                        .map( { DomainItem(name: $0.name, status: .unclaimed)} )
            
            self.selectionViewController?.didSelect(domains: newDomains,
                                           includingPaidDomains: paidDomains,
                                           for: self.activeWallet) { [weak self] in self?.activityIndicator.startAnimating() }
        }
    }
    
    @IBAction func didTapCustomWalletButton(_ sender: UIButton) {
        selectionViewController?.requestCustomWallets(from: self) {
            wallets, activeWallet in
            self.updateWalletsUI (wallets: wallets, activeWallet: activeWallet)
        }
    }
    
    @IBAction func didTapSelectAllButton(_ sender: UIButton) {
        guard let limit = mintingLimit else { return }
        let totalDomainCount = domainEntries.count
        
        if totalDomainCount <= limit {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.domainsTableView.selectAllRows()
                self.updateButtons()
            }
        } else {
            let selectedDomainsCount = self.selectedRows.count
            let stillToSelectCount = limit - selectedDomainsCount
            Utilities.selectFromTop(count: stillToSelectCount,
                                    inAdditionTo: selectedRows,
                                    totalCount: totalDomainCount) { [weak self] rowToSelectIndex in
                let indexPath = IndexPath(row: rowToSelectIndex, section: 0)
                self?.domainsTableView.selectRow(at: indexPath,
                                                 animated: true,
                                                 scrollPosition: .none)
            }
            updateButtons()
            let alert = UIAlertController(title: nil, message: "You have selected max: \(limit) domains", preferredStyle: .alert)
            self.selectionViewController?.present(alert, animated: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                alert.dismiss(animated: true)
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if self.activeWallet == nil {
            self.walletViewHeight.constant = 0
        }
        self.containerView.layoutIfNeeded()
        domainsTableView.register(UnclaimedDomainCell.self, forCellReuseIdentifier: UnclaimedDomainCell.name)
        domainsTableView.dataSource = self
        domainsTableView.delegate = self
        domainsTableView.allowsMultipleSelection = true
        setupStrings()
                
        updateMintSelectedButton()
    }
    
    private func configureActiveWalletView() {
        guard let activeWallet = self.activeWallet else {
            Debugger.printFailure("Couldn't find active wallet by its address", critical: true)
            return
        }
        activeWalletView.configure(with: activeWallet)
        DispatchQueue.main.async { [weak self] in
            self?.claimToCustomButton.isHidden = true
        }
    }
    
    private func updateWalletsUI (wallets: [UDWallet], activeWallet: UDWallet?) {
        self.wallets = wallets
        self.activeWallet = activeWallet
        self.configureActiveWalletView()
    }
    
    private func updateButtons() {
        updateMintSelectedButton()
        updateSelecAllButton()
    }
    
    func triggerUpperWalletView(animated: Bool = true) {
        self.walletViewHeight.constant = 96
        let duration: TimeInterval = animated ? 1.2 : 0.0
        UIView.animate (withDuration: duration, delay: 0, usingSpringWithDamping: 0.25, initialSpringVelocity: 0.5, options: .curveEaseOut) {
            self.containerView.layoutIfNeeded()
        }
    }
    
    private func setupStrings() {
        youCanClaimTitle.text = selectionViewController?.controller?.selectionTitle
        claimSelectedButton.setTitle(String.Constants.mintSelectedDomains.localized(), for: .normal)
        claimToCustomButton.setTitle(String.Constants.mintDomainsToCustomWallet.localized(), for: .normal)
    }
    
    private func updateMintSelectedButton() {
        let isEnabled = selectedRows.count > 0
        claimSelectedButton.isEnabled = isEnabled
    }
    
    private func updateSelecAllButton() {
        selectAllButton.isEnabled = selectedRows.count < domainEntries.count && selectedRows.count < mintingLimit ?? 0
    }
    
    private func isSelectable(_ entry: DomainEntry) -> Bool {
        guard let wallet = activeWallet else {
            return true
        }
        guard wallet.walletState == .externalLinked else { return true }
        if DomainName.isZilByExtension(ext: entry.name.getTldName() ?? "") {
            if User.instance.getAppVersionInfo()
                .mintingZilTldOnPolygonReleased {
                return true }
            return wallet.extractZilWallet() != nil
        } else {
            return wallet.extractEthWallet() != nil
        }
    }

    override func set(data: SelectionData) {
        guard let domains = data[.paidDomainNames] as? [String] else {
            Debugger.printFailure("no domains array", critical: true)
            return
        }
        guard let nonPaidDomains = data[.nonPaidDomainNames] as? [String] else {
            Debugger.printFailure("no domains array", critical: true)
            return
        }
        
        self.domainEntries = domains.sorted(by: {$0 < $1})
                                    .map({DomainEntry(name: $0, hasCredit: true)})
            + nonPaidDomains.sorted(by: {$0 < $1})
                            .map({DomainEntry(name: $0, hasCredit: false)})
    }
}

extension SelectAndClaimFlowStep: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        domainEntries.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: UnclaimedDomainCell.name, for: indexPath as IndexPath) as? UnclaimedDomainCell else { return UITableViewCell() }
        
        let entry = domainEntries[indexPath.row]
        let isSelectable = isSelectable(entry)
        cell.configure(with: domainEntries[indexPath.row], isSelectable: isSelectable)
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let domainCell = cell as? UnclaimedDomainCell else { return  }
        domainCell.isHighlighted = selectedRows.contains(indexPath.row)
    }
}

extension SelectAndClaimFlowStep: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if let limit = mintingLimit,
           selectedRows.count >= limit {
            self.selectionViewController?.showSimpleAlert(title: "Max count reached", body: "You have selected max: \(limit) domains")
            return nil
        }
        let entry = domainEntries[indexPath.row]
        let isSelectable = isSelectable(entry)
        return isSelectable ? indexPath : nil
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        updateButtons()
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        updateButtons()
    }
}
