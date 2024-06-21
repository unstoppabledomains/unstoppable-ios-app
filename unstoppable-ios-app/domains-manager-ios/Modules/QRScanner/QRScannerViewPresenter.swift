//
//  QRScannerViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 06.06.2022.
//

import Foundation
import Combine

@MainActor
protocol QRScannerViewPresenterProtocol: BasePresenterProtocol {
    func didActivateCamera()
    func didRecognizeQRCodes(_ qrCodes: [QRCode])
    func failedToSetupCaptureSession()
    func didTapConnectedAppsView()
    func didTapDomainInfoView()
    func didSelectBlockchainType(_ blockchainType: BlockchainType)
}

@MainActor
final class QRScannerViewPresenter: ViewAnalyticsLogger {
    
    internal weak var view: QRScannerViewProtocol?
    private var isAcceptingQRCodes = true
    private let walletConnectServiceV2: WalletConnectServiceV2Protocol
    private let networkReachabilityService: NetworkReachabilityServiceProtocol?
    private let walletsDataService: WalletsDataServiceProtocol
    private var selectedWallet: WalletEntity
    private var blockchainType: BlockchainType = .Ethereum // UserDefaults.selectedBlockchainType
    private var cancellables: Set<AnyCancellable> = []
    var analyticsName: Analytics.ViewName { view?.analyticsName ?? .unspecified }
    var qrRecognizedCallback: MainActorAsyncCallback?

    init(view: QRScannerViewProtocol,
         selectedWallet: WalletEntity,
         walletConnectServiceV2: WalletConnectServiceV2Protocol,
         networkReachabilityService: NetworkReachabilityServiceProtocol?,
         walletsDataService: WalletsDataServiceProtocol) {
        self.view = view
        self.selectedWallet = selectedWallet
        self.walletConnectServiceV2 = walletConnectServiceV2
        self.networkReachabilityService = networkReachabilityService
        self.walletsDataService = walletsDataService
        walletsDataService.selectedWalletPublisher.receive(on: DispatchQueue.main).sink { [weak self] selectedWallet in
            if let selectedWallet {
                self?.setSelected(wallet: selectedWallet)
            }
        }.store(in: &cancellables)
    }
}

typealias QRCode = String

// MARK: - QRScannerViewPresenterProtocol
extension QRScannerViewPresenter: QRScannerViewPresenterProtocol {
    func viewDidLoad() {
        appContext.wcRequestsHandlingService.addListener(self)
        showNumberOfAppsConnected()
        setSelected(wallet: selectedWallet)
    }
    
    func didActivateCamera() {
        setBlockchainTypePicker()
    }
   
    func didRecognizeQRCodes(_ qrCodes: [QRCode]) {
        guard let qrCode = qrCodes.first, isAcceptingQRCodes else { return }

        isAcceptingQRCodes = false
        UDVibration.buttonTap.vibrate()
        logAnalytic(event: .didRecognizeQRCode, parameters: [.domainName: selectedWallet.rrDomain?.name ?? "",
                                                             .wallet: selectedWallet.address])
        Task {
            guard let view = self.view else { return }
            
            guard networkReachabilityService?.isReachable == true else {
                await appContext.pullUpViewService.showYouAreOfflinePullUp(in: view,
                                                                       unavailableFeature: .scanning)
                waitAndResumeAcceptingQRCodes()
                return
            }
            
            do {
                let wcRequest = try await getWCConnectionRequest(for: qrCode)
                try await handleWCRequest(wcRequest)
                await view.dismiss(animated: false)
                view.navigationController?.popViewController(animated: true)
                qrRecognizedCallback?()
            } catch {
                waitAndResumeAcceptingQRCodes()
                Debugger.printFailure("Failed to get request from QR code", critical: false)
            }
        }
    }
    
    func failedToSetupCaptureSession() {
        view?.removeBlockchainTypeSelection()
    }
    
    func didTapConnectedAppsView() {
        guard let view = self.view else { return }
        
        UDVibration.buttonTap.vibrate()
        Task.detached(priority: .background) { [weak self] in
            guard let self else { return }
            await view.stopCaptureSession()
            await UDRouter().showConnectedAppsListScreen(in: view)
            await showNumberOfAppsConnected()
            await view.startCaptureSession()
        }
    }
    
    func didTapDomainInfoView() {
        UDVibration.buttonTap.vibrate()
        guard let view = self.view else { return }
        UDRouter().showProfileSelectionScreen(selectedWallet: selectedWallet,
                                              in: view)
    }
    
    func didSelectBlockchainType(_ blockchainType: BlockchainType) {
        guard blockchainType != UserDefaults.selectedBlockchainType else { return }
        
        UserDefaults.selectedBlockchainType = blockchainType
        self.blockchainType = blockchainType
        setBlockchainTypePicker()
        setSelected(wallet: selectedWallet)
    }
}

// MARK: - WalletConnectServiceListener
extension QRScannerViewPresenter: WalletConnectServiceConnectionListener {
    nonisolated
    func didConnect(to app: UnifiedConnectAppInfo) {
        Task { @MainActor in
            showNumberOfAppsConnected()
            waitAndResumeAcceptingQRCodes()
        }
    }
    
    nonisolated
    func didCompleteConnectionAttempt() {
        Task { @MainActor in
            waitAndResumeAcceptingQRCodes()
        }
    }
    
    nonisolated
    func didDisconnect(from app: UnifiedConnectAppInfo) {
        Task { @MainActor in
            showNumberOfAppsConnected()
        }
    }
    
    internal func getCurrentConnectionTarget() -> UDWallet? {
        selectedWallet.udWallet
    }
    
    private func resumeAcceptingQRCodes() {
        isAcceptingQRCodes = true
    }
}

// MARK: - Private functions
private extension QRScannerViewPresenter {
    func setBlockchainTypePicker() {
        view?.setBlockchainTypeSelectionWith(availableTypes: BlockchainType.supportedCases, selectedType: blockchainType)
    }
    
    func setSelected(wallet: WalletEntity) {
        let wallets = walletsDataService.wallets
        self.selectedWallet = wallet
        
        view?.setWith(wallet: wallet,
                      isSelectable: wallets.count > 1)
    }
    
    func setSelectedWalletInfo() {
        if let wallet = appContext.walletsDataService.selectedWallet {
            setSelected(wallet: wallet)
        }
    }

    func showNumberOfAppsConnected() {
        let appsConnected = walletConnectServiceV2.getConnectedApps()
        view?.setWith(appsConnected: appsConnected.count)
    }
    
    func getWCConnectionRequest(for code: QRCode) async throws -> WCRequest {
        do {
            let uriV2 = try appContext.walletConnectServiceV2.getWCV2Request(for: code)
            return WCRequest.connectWallet(WalletConnectServiceV2.ConnectWalletRequest(uri: uriV2))
        } catch {
            Debugger.printFailure("QRCode failed to convert to url: \(code)", critical: false)
            if let view = self.view {
                await appContext.pullUpViewService.showWCInvalidQRCodePullUp(in: view)
            }
            throw error
        }
    }
    
    func handleWCRequest(_ request: WCRequest) async throws {
        guard let target = getCurrentConnectionTarget() else {
            throw WalletConnectRequestError.uiHandlerNotSet
        }
        
        try await appContext.wcRequestsHandlingService.handleWCRequest(request, target: target)
    }
    
    func waitAndResumeAcceptingQRCodes() {
        Task {
            try? await wait(for: 0.5)
            resumeAcceptingQRCodes()
        }
    }
    
    func wait(for interval: TimeInterval) async throws {
        await Task.sleep(seconds: interval)
    }
}
