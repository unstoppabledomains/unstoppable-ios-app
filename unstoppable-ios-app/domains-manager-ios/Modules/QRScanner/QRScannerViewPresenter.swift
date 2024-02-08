//
//  QRScannerViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 06.06.2022.
//

import Foundation

@MainActor
protocol QRScannerViewPresenterProtocol: BasePresenterProtocol {
    func didRecognizeQRCodes(_ qrCodes: [QRCode])
    func failedToSetupCaptureSession()
    func didTapEnableCameraAccess()
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
    private let udWalletsService: UDWalletsServiceProtocol
    private var selectedWallet: WalletEntity
    private var blockchainType: BlockchainType = UserDefaults.selectedBlockchainType
    var analyticsName: Analytics.ViewName { view?.analyticsName ?? .unspecified }
    var qrRecognizedCallback: MainActorAsyncCallback?
    
    init(view: QRScannerViewProtocol,
         selectedWallet: WalletEntity,
         walletConnectServiceV2: WalletConnectServiceV2Protocol,
         networkReachabilityService: NetworkReachabilityServiceProtocol?,
         udWalletsService: UDWalletsServiceProtocol) {
        self.view = view
        self.selectedWallet = selectedWallet
        self.walletConnectServiceV2 = walletConnectServiceV2
        self.networkReachabilityService = networkReachabilityService
        self.udWalletsService = udWalletsService
    }
}

typealias QRCode = String

// MARK: - QRScannerViewPresenterProtocol
extension QRScannerViewPresenter: QRScannerViewPresenterProtocol {
    func viewDidLoad() {
        guard let view = self.view else { return }
        appContext.wcRequestsHandlingService.addListener(self)
        view.setState(.askingForPermissions)
        let selectedDomain = self.selectedWallet
        Task.detached(priority: .low) { [weak self] in
            let isGranted = await appContext.permissionsService.checkPermissionsFor(functionality: .camera)
            
            if isGranted {
                await self?.setBlockchainTypePicker()
                await view.setState(.scanning)
            } else {
                await view.setState(.permissionsDenied)
            }
            
            await self?.showNumberOfAppsConnected()
            await self?.setSelected(wallet: selectedDomain)
        }
    }
    
    func viewDidAppear() {
        Task {
            let isGranted = await appContext.permissionsService.checkPermissionsFor(functionality: .camera)
            
            if isGranted {
                view?.startCaptureSession()
            }
        }
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
        view?.setState(.cameraNotAvailable)
        view?.removeBlockchainTypeSelection()
    }
    
    func didTapEnableCameraAccess() {
        Task {
            guard let view = self.view else { return }
            
            let isGranted = await appContext.permissionsService.askPermissionsFor(functionality: .camera,
                                                                                  in: view,
                                                                                  shouldShowAlertIfNotGranted: false)
            if isGranted {
                setBlockchainTypePicker()
                view.setState(.scanning)
                view.startCaptureSession()
            } else {
                view.openAppSettings()
            }
        }
    }
    
    func didTapConnectedAppsView() {
        guard let view = self.view else { return }
        
        UDVibration.buttonTap.vibrate()
        Task {
            view.stopCaptureSession()
            await UDRouter().showConnectedAppsListScreen(in: view)
            showNumberOfAppsConnected()
            view.startCaptureSession()
        }
    }
    
    func didTapDomainInfoView() {
        UDVibration.buttonTap.vibrate()
        Task {
            guard let view = self.view else { return }
            view.stopCaptureSession()
            do {
                let result = try await UDRouter().showSignTransactionDomainSelectionScreen(selectedDomain: selectedWallet.rrDomain!,
                                                                                           swipeToDismissEnabled: true,
                                                                                           in: view)
                if let wallet = appContext.walletsDataService.wallets.first(where: { wallet in
                    wallet.domains.first(where: { $0.isSameEntity(result) }) != nil
                }) {
                    setSelected(wallet: wallet)
                }
            } catch { }
            view.startCaptureSession()
        }
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
    
    internal func getCurrentConnectionTarget() -> (UDWallet, DomainItem)? {
        guard let domain = selectedWallet.rrDomain?.toDomainItem() else { return nil }
        return (selectedWallet.udWallet, domain)
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
        let displayInfo = wallet.displayInfo
        let domains = wallet.domains
        self.selectedWallet = wallet
        let balance = wallet.balanceFor(blockchainType: blockchainType)
        
        view?.setWith(selectedDomain: wallet.rrDomain,
                      wallet: displayInfo,
                      balance: balance,
                      isSelectable: domains.count > 1)
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
            throw ScanningError.notSupportedQRCode
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

extension QRScannerViewPresenter {
    enum ScanningError: String, LocalizedError {
        case notSupportedQRCode
        case notSupportedQRCodeV2
        
        public var errorDescription: String? { rawValue }

    }
}
