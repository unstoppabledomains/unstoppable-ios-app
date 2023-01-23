//
//  SelectAndImportWalletFlowStep.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 13.08.2021.
//

import UIKit

class SelectAndImportWalletFlowStep: SecureSelectionFlowStep {
        
    @IBOutlet weak var importSelectedButton: UIButton!
    @IBOutlet weak var selectAllButton: UIButton!
    
    @IBOutlet weak var walletsTableView: UITableView!
    @IBOutlet weak var youCanImportTitle: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var walletEntries: [UDWallet] = []
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        walletsTableView.register(UnclaimedDomainCell.self, forCellReuseIdentifier: UnclaimedDomainCell.name)
        walletsTableView.dataSource = self
        walletsTableView.delegate = self
        walletsTableView.allowsMultipleSelection = true
        let isEnabled = (walletsTableView.indexPathsForSelectedRows ?? []).count > 0
        updateMintSelectedButton(isEnabled)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setupStrings()
    }
    
    @IBAction func didTapImportSelectedButton(_ sender: UIButton) {
        guard let viewController = selectionViewController else { return }

        AuthentificationService.instance.verifyWith(uiHandler: viewController, purpose: .confirm, completionCallback: self.proceedWithSelectedWallets(), cancellationCallback: nil)
    }
    
    func proceedWithSelectedWallets() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard let selectedIndexes = self.walletsTableView.indexPathsForSelectedRows,
                  selectedIndexes.count > 0 else {
                Debugger.printFailure("No domains selected")
                return
            }
            let newWallets = selectedIndexes.map( {self.walletEntries[$0.row]} )
            self.selectionViewController?.didSelect(wallets: newWallets)
        }
    }
    
    @IBAction func didTapSelectAllButton(_ sender: UIButton) {
        selectAllWallets()
    }
    
    func proceedWithAllWallets() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let newWallets: [UDWallet] = self.walletEntries
            self.selectionViewController?.didSelect(wallets: newWallets)
        }
    }
    
    func selectAllWallets() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            for row in 0..<self.walletsTableView.numberOfRows(inSection: 0) {
                self.walletsTableView.selectRow(at: IndexPath(row: row, section: 0), animated: false, scrollPosition: .none)
                    }
        }
    }
    
    private func setupStrings() {
        youCanImportTitle.text = selectionViewController?.controller?.selectionTitle
    }
    
    private func updateMintSelectedButton(_ isEnabled: Bool) {
        importSelectedButton.isEnabled = isEnabled
    }
    
    override func set(data: SelectionData) {
        guard let wallets = data[.unverifiedWallets] as? [UDWallet] else {
            Debugger.printFailure("no wallets array", critical: true)
            return
        }
        self.walletEntries = wallets.sorted(by: { $0.aliasName < $1.aliasName })
    }
}

extension SelectAndImportWalletFlowStep: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        walletEntries.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: UnclaimedDomainCell.name, for: indexPath as IndexPath) as? UnclaimedDomainCell else { return UITableViewCell() }
        
        cell.configure(with: walletEntries[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let domainCell = cell as? UnclaimedDomainCell else { return  }
        if let selections = tableView.indexPathsForSelectedRows, selections.contains(indexPath) {
            domainCell.isHighlighted = true
        }
    }
}

extension SelectAndImportWalletFlowStep: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        return indexPath
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let isEnabled = (tableView.indexPathsForSelectedRows ?? []).count > 0
        updateMintSelectedButton(isEnabled)
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let isEnabled = (tableView.indexPathsForSelectedRows ?? []).count > 0
        updateMintSelectedButton(isEnabled)
    }
}
