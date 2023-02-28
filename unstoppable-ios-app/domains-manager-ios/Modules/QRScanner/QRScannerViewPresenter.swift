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

final class QRScannerViewPresenter: ViewAnalyticsLogger {
    
    internal weak var view: QRScannerViewProtocol?
    private var isAcceptingQRCodes = true
    private let dataAggregatorService: DataAggregatorServiceProtocol
    private let walletConnectService: WalletConnectServiceProtocol
    private let walletConnectServiceV2: WalletConnectServiceV2Protocol
    private let networkReachabilityService: NetworkReachabilityServiceProtocol?
    private let udWalletsService: UDWalletsServiceProtocol
    private var selectedDomain: DomainDisplayInfo
    var analyticsName: Analytics.ViewName { view?.analyticsName ?? .unspecified }
    var qrRecognizedCallback: EmptyAsyncCallback?
    
    init(view: QRScannerViewProtocol,
         selectedDomain: DomainDisplayInfo,
         dataAggregatorService: DataAggregatorServiceProtocol,
         walletConnectService: WalletConnectServiceProtocol,
         walletConnectServiceV2: WalletConnectServiceV2Protocol,
         networkReachabilityService: NetworkReachabilityServiceProtocol?,
         udWalletsService: UDWalletsServiceProtocol) {
        self.view = view
        self.selectedDomain = selectedDomain
        self.dataAggregatorService = dataAggregatorService
        self.walletConnectService = walletConnectService
        self.walletConnectServiceV2 = walletConnectServiceV2
        self.networkReachabilityService = networkReachabilityService
        self.udWalletsService = udWalletsService
    }
}

// MARK: - WalletConnectServiceDelegate
extension QRScannerViewPresenter: QRScannerViewPresenterProtocol {
    @MainActor
    func viewDidLoad() {
        guard let view = self.view else { return }
        dataAggregatorService.addListener(self)
        walletConnectService.addListener(self)
        walletConnectServiceV2.addListener(self)
        view.setState(.askingForPermissions)
        let selectedDomain = self.selectedDomain
        Task.detached(priority: .low) { [weak self] in
            let isGranted = await appContext.permissionsService.checkPermissionsFor(functionality: .camera)
            
            if isGranted {
                await self?.setBlockchainTypePicker()
                await view.setState(.scanning)
            } else {
                await view.setState(.permissionsDenied)
            }
            
            await self?.showNumberOfAppsConnected()
            await self?.showInfoFor(domain: selectedDomain, balance: nil)
        }
    }
    @MainActor
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
        logAnalytic(event: .didRecognizeQRCode, parameters: [.domainName: selectedDomain.name])
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
                view.cNavigationController?.popViewController(animated: true)
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
            await showNumberOfAppsConnected()
            view.startCaptureSession()
        }
    }
    
    func didTapDomainInfoView() {
        UDVibration.buttonTap.vibrate()
        Task {
            guard let view = self.view else { return }
            view.stopCaptureSession()
            do {
                let result = try await UDRouter().showSignTransactionDomainSelectionScreen(selectedDomain: selectedDomain,
                                                                                           swipeToDismissEnabled: true,
                                                                                           in: view)
                await showInfoFor(domain: result.0, balance: result.1)
            } catch { }
            view.startCaptureSession()
        }
    }
    
    func didSelectBlockchainType(_ blockchainType: BlockchainType) {
        guard blockchainType != UserDefaults.selectedBlockchainType else { return }
        
        UserDefaults.selectedBlockchainType = blockchainType
        setBlockchainTypePicker()
        Task {
            await showInfoFor(domain: selectedDomain, balance: nil)
        }
    }
}

// MARK: - WalletConnectServiceListener
extension QRScannerViewPresenter: WalletConnectServiceListener {
    func didConnect(to app: PushSubscriberInfo?) {
        Task {
            await showNumberOfAppsConnected()
        }
        waitAndResumeAcceptingQRCodes()
    }
    
    func didCompleteConnectionAttempt() {
        waitAndResumeAcceptingQRCodes()
    }
    
    func didDisconnect(from app: PushSubscriberInfo?) {
        Task {
            await showNumberOfAppsConnected()
        }
    }
    
    internal func getCurrentConnectionTarget() async -> (UDWallet, DomainItem)? {
        let wallets = await dataAggregatorService.getWalletsWithInfo().map({ $0.wallet })
        
        guard let domain = try? await dataAggregatorService.getDomainWith(name: selectedDomain.name),
              let wallet = wallets.first(where: { $0.owns(domain: domain) }) else { return nil }
        return (wallet, domain)
    }
    
    private func resumeAcceptingQRCodes() {
        isAcceptingQRCodes = true
    }
}

// MARK: - DataAggregatorServiceListener
extension QRScannerViewPresenter: DataAggregatorServiceListener {
    func dataAggregatedWith(result: DataAggregationResult) {
        Task {
            switch result {
            case .success(let result):
                switch result {
                case .domainsUpdated(let domains), .domainsPFPUpdated(let domains):
                    if let domain = domains.first(where: { $0.name == self.selectedDomain.name }) {
                        self.selectedDomain = domain
                        await showInfoFor(domain: domain, balance: nil)
                    } else if domains.isEmpty {
                        await view?.cNavigationController?.popViewController(animated: true)
                    } else {
                        await setPrimaryDomainInfo()
                    }
                case .walletsListUpdated, .primaryDomainChanged:
                    return
                }
            case .failure:
                return
            }
        }
    }
}

// MARK: - Private functions
private extension QRScannerViewPresenter {
    @MainActor
    func setBlockchainTypePicker() {
        view?.setBlockchainTypeSelectionWith(availableTypes: BlockchainType.supportedCases, selectedType: UserDefaults.selectedBlockchainType)
    }
    
    func showInfoFor(domain: DomainDisplayInfo, balance: WalletBalance?) async {
        guard let walletWithInfo = await dataAggregatorService.getWalletsWithInfo().first(where: { $0.wallet.owns(domain: domain) }),
              let displayInfo = walletWithInfo.displayInfo else { return }
        let domains = await dataAggregatorService.getDomainsDisplayInfo()
        self.selectedDomain = domain
        
        await view?.setWith(selectedDomain: domain,
                            wallet: displayInfo,
                            balance: balance,
                            isSelectable: domains.count > 1)
        
        if balance == nil {
            do {
                let walletBalance = try await udWalletsService.getBalanceFor(walletAddress: walletWithInfo.wallet.address,
                                                                             blockchainType: UserDefaults.selectedBlockchainType,
                                                                             forceRefresh: false)
                await view?.setWith(selectedDomain: domain,
                                    wallet: displayInfo,
                                    balance: walletBalance,
                                    isSelectable: domains.count > 1)
            } catch { }
        }
    }
    
    func setPrimaryDomainInfo() async {
        let domains = await dataAggregatorService.getDomainsDisplayInfo()
        if let primaryDomain = domains.first(where: { $0.isPrimary })  {
            await showInfoFor(domain: primaryDomain, balance: nil)
        }
    }

    func showNumberOfAppsConnected() async {
        let appsConnected = await walletConnectServiceV2.getConnectedApps()
        await view?.setWith(appsConnected: appsConnected.count)
    }
    
    func getWCConnectionRequest(for code: QRCode) async throws -> WCRequest {
        if let wcurl = code.wcurl {
            let connectWalletRequest = WalletConnectService.ConnectWalletRequest.version1(wcurl)
            return WCRequest.connectWallet(connectWalletRequest)
        }
        
        do {
            let uriV2 = try appContext.walletConnectServiceV2.getWCV2Request(for: code)
            return WCRequest.connectWallet(WalletConnectService.ConnectWalletRequest.version2(uriV2))
        } catch {
            Debugger.printFailure("QRCode failed to convert to url: \(code)", critical: false)
            if let view = self.view {
                await appContext.pullUpViewService.showWCInvalidQRCodePullUp(in: view)
            }
            throw ScanningError.notSupportedQRCode
        }
    }
    
    func handleWCRequest(_ request: WCRequest) async throws {
        guard let target = await getCurrentConnectionTarget() else {
            throw WalletConnectService.Error.uiHandlerNotSet
        }
        
        try await WalletConnectService.handleWCRequest(request, target: target)
    }
    
    func waitAndResumeAcceptingQRCodes() {
        Task {
            try? await wait(for: 0.5)
            resumeAcceptingQRCodes()
        }
    }
    
    func wait(for interval: TimeInterval) async throws {
        try await Task.sleep(seconds: interval)
    }
}

extension QRScannerViewPresenter {
    enum ScanningError: Error {
        case notSupportedQRCode
        case notSupportedQRCodeV2
    }
}
