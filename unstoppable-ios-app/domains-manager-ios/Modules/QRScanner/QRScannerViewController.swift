//
//  QRScannerViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 06.06.2022.
//

import UIKit
import AVFoundation

@MainActor
protocol QRScannerViewProtocol: BaseViewControllerProtocol {
    func startCaptureSession()
    func stopCaptureSession()
    func setWith(wallet: WalletEntity, isSelectable: Bool)
    func setWith(appsConnected: Int)
    func setBlockchainTypeSelectionWith(availableTypes: [BlockchainType], selectedType: BlockchainType)
    func removeBlockchainTypeSelection()
}

@MainActor
final class QRScannerViewController: BaseViewController {
    
    @IBOutlet private weak var scannerPreviewView: QRScannerPreviewView!
    @IBOutlet private weak var selectionItemsStack: UIStackView!
    @IBOutlet private weak var appsConnectedItemView: ListItemView!
    @IBOutlet private weak var selectedDomainItemView: QRScannerDomainInfoView!
    
    private var availableBlockchainTypes: [BlockchainType] = []
    private var selectedBlockchainType: BlockchainType?

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }
    override var analyticsName: Analytics.ViewName { .scanning }
    
    var presenter: QRScannerViewPresenterProtocol!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
        presenter.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
                
        setNavBarTint(.white)
    }
  
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        presenter.viewDidAppear()
        setNavBarTint(.white)
    }
    
    override var navBarTitleAttributes: [NSAttributedString.Key : Any]? { [.foregroundColor : UIColor.foregroundOnEmphasis,
                                                                     .font: UIFont.currentFont(withSize: 16, weight: .semibold)] }
    
    func previousInteractiveTransitionStartThreshold() -> CGFloat? { 1 }
}

// MARK: - QRScannerViewProtocol
extension QRScannerViewController: QRScannerViewProtocol {
    func startCaptureSession() {
        scannerPreviewView.startCaptureSession()
    }
    
    func stopCaptureSession() {
        scannerPreviewView.stopCaptureSession()
    }
    
    func setWith(wallet: WalletEntity, isSelectable: Bool) {
        selectedDomainItemView.setWith(wallet: wallet, isSelectable: isSelectable)
    }
    
    func setWith(appsConnected: Int) {
        appsConnectedItemView.setWith(icon: .widgetIcon, text: String.Constants.pluralNAppsConnected.localized(appsConnected, appsConnected))
        appsConnectedItemView.isHidden = appsConnected <= 0
    }
    
    func setBlockchainTypeSelectionWith(availableTypes: [BlockchainType], selectedType: BlockchainType) {
        self.availableBlockchainTypes = availableTypes
        self.selectedBlockchainType = selectedType
        
        let button = UIButton()
        button.tintColor = .foregroundOnEmphasis
        button.setImage(.dotsCircleIcon, for: .normal)
        
        // Actions
        let actions: [UIAction] = availableBlockchainTypes.map({ type in
            let action = UIAction(title: type.rawValue,
                                  image: type.icon,
                                  identifier: .init(UUID().uuidString),
                                  handler: { [weak self] _ in
                self?.didSelectBlockchainType(type)
            })
            if type == selectedType {
                action.state = .on
            }
            return action
        })
        
        let menu = UIMenu(title: String.Constants.showWalletBalanceIn.localized(), children: actions)
        button.showsMenuAsPrimaryAction = true
        button.menu = menu
        button.addAction(UIAction(handler: { [weak self] _ in
            self?.logButtonPressedAnalyticEvents(button: .scanningSelectNetwork)
            UDVibration.buttonTap.vibrate()
        }), for: .menuActionTriggered)
        
        let rightItem: UIBarButtonItem = UIBarButtonItem(customView: button)
        rightItem.tintColor = .foregroundOnEmphasis
        
        navigationItem.rightBarButtonItem = rightItem
    }
    
    func removeBlockchainTypeSelection() {
        navigationItem.rightBarButtonItem = nil
    }
}

// MARK: - Actions
private extension QRScannerViewController {
    @IBAction func didTapConnectedAppsView() {
        logButtonPressedAnalyticEvents(button: .scanningConnectedApps)
        presenter.didTapConnectedAppsView()
    }
    
    @IBAction func didTapDomainInfoView() {
        logButtonPressedAnalyticEvents(button: .scanningSelectDomain)
        presenter.didTapDomainInfoView()
    }
}

// MARK: - Private functions
private extension QRScannerViewController {
    func didSelectBlockchainType(_ blockchainType: BlockchainType) {
        logAnalytic(event: .didSelectChainNetwork,
                    parameters: [.chainNetwork: blockchainType.rawValue])
        UDVibration.buttonTap.vibrate()
        presenter.didSelectBlockchainType(blockchainType)
    }
}

// MARK: - Setup functions
private extension QRScannerViewController {
    func setup() {
        view.backgroundColor = .black
        title = String.Constants.scanQRCodeTitle.localized()
        navigationController?.navigationBar.tintColor = .white
        appsConnectedItemView.isHidden = true
        
        scannerPreviewView.onEvent = { [weak self] event in
            DispatchQueue.main.async {
                self?.handleScannerPreviewEvent(event)
            }
        }
    }
    
    func handleScannerPreviewEvent(_ event: QRScannerPreviewView.Event) {
        switch event {
        case .didChangeState(let state):
            switch state {
            case .scanning:
                selectionItemsStack.isHidden = false
                presenter.didActivateCamera()
            case .askingForPermissions:
                return
            case .permissionsDenied, .cameraNotAvailable:
                selectionItemsStack.isHidden = true
            }
        case .didRecognizeQRCodes(let codes):
            presenter.didRecognizeQRCodes(codes)
        case .didFailToSetupCaptureSession:
            presenter.failedToSetupCaptureSession()
        }
    }
}

import SwiftUI

struct QRScannerViewControllerWrapper: UIViewControllerRepresentable {
    
    var selectedWallet: WalletEntity
    var qrRecognizedCallback: MainActorAsyncCallback
    
    func makeUIViewController(context: Context) -> QRScannerViewController {
        UDRouter().buildQRScannerModule(selectedWallet: selectedWallet,
                                        qrRecognizedCallback: qrRecognizedCallback)
    }
    
    func updateUIViewController(_ uiViewController: QRScannerViewController, context: Context) { }
}
