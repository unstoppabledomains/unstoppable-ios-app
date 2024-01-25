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
    func setState(_ state: QRScannerViewController.State)
    func setWith(selectedDomain: DomainDisplayInfo?, wallet: WalletDisplayInfo, balance: WalletTokenPortfolio?, isSelectable: Bool)
    func setWith(appsConnected: Int)
    func setBlockchainTypeSelectionWith(availableTypes: [BlockchainType], selectedType: BlockchainType)
    func removeBlockchainTypeSelection()
}

@MainActor
final class QRScannerViewController: BaseViewController {
    
    @IBOutlet private weak var captureSessionContainerView: UIView!
    @IBOutlet private weak var scannerSightView: QRScannerSightView!
    @IBOutlet private weak var selectionItemsStack: UIStackView!
    @IBOutlet private weak var appsConnectedItemView: ListItemView!
    @IBOutlet private weak var selectedDomainItemView: QRScannerDomainInfoView!
    
    private let cameraSessionService = CameraSessionService()
    private var previewLayer: AVCaptureVideoPreviewLayer?
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
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        DispatchQueue.main.async { [weak self] in
            self?.updateRectOfInterest()
        }
    }
    
    override var navBarTitleAttributes: [NSAttributedString.Key : Any]? { [.foregroundColor : UIColor.foregroundOnEmphasis,
                                                                     .font: UIFont.currentFont(withSize: 16, weight: .semibold)] }
    
    override var navBackButtonConfiguration: CNavigationBarContentView.BackButtonConfiguration {
        .init(backArrowIcon: .navArrowLeft, tintColor: .foregroundOnEmphasis, backTitleVisible: false)
    }
    
    func previousInteractiveTransitionStartThreshold() -> CGFloat? { 1 }
}

// MARK: - QRScannerViewProtocol
extension QRScannerViewController: QRScannerViewProtocol {
    func startCaptureSession() {
        Task.detached(priority: .background) { [weak self] in
            guard let self else { return }
            
            if !(await self.cameraSessionService.isSessionSet) {
                await self.startCamera()
            }
            await self.cameraSessionService.startCaptureSession()
        }
    }
    
    func stopCaptureSession() {
        Task {
            await cameraSessionService.stopCaptureSession()
        }
    }
    
    func setState(_ state: QRScannerViewController.State) {
        switch state {
        case .scanning:
            selectionItemsStack.isHidden = false
            view.firstSubviewOfType(QRScannerPermissionsView.self)?.removeFromSuperview()
            scannerSightView.setBlurHidden(false)
        case .askingForPermissions:
            scannerSightView.setBlurHidden(true)
        case .permissionsDenied, .cameraNotAvailable:
            selectionItemsStack.isHidden = true
            let permissionsView = QRScannerPermissionsView()
            permissionsView.embedInSuperView(view)
            permissionsView.enableCameraButtonPressedCallback = { [weak self] in
                self?.presenter.didTapEnableCameraAccess()
            }
            if state == .cameraNotAvailable {
                permissionsView.setCameraNotAvailable()
            }
            view.bringSubviewToFront(permissionsView)
        }
    }
    
    func setWith(selectedDomain: DomainDisplayInfo?, wallet: WalletDisplayInfo, balance: WalletTokenPortfolio?, isSelectable: Bool) {
        selectedDomainItemView.setWith(domain: selectedDomain, wallet: wallet, balance: balance, isSelectable: isSelectable)
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.cNavigationController?.updateNavigationBar()
        }
    }
    
    func removeBlockchainTypeSelection() {
        navigationItem.rightBarButtonItem = nil
    }
}

// MARK: - InteractivePushNavigation
extension QRScannerViewController: CNavigationControllerChildTransitioning {
    func popAnimatedTransitioning(to viewController: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        logAnalytic(event: .swipeToHome)
        return CNavigationControllerSlidePopAnimation()
    }
    
    func popNavBarAnimatedTransitioning(to viewController: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        CNavigationBarSlidePopAnimation()
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate
extension QRScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        let codes = Array(metadataObjects.lazy.compactMap({ ($0 as? AVMetadataMachineReadableCodeObject)?.stringValue }).filter({ !$0.isEmpty }))
        presenter.didRecognizeQRCodes(codes)
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
    func updateRectOfInterest()  {
        Task {
            let aimFrame = scannerSightView.aimFrame
            let rect = previewLayer?.metadataOutputRectConverted(fromLayerRect: aimFrame) ?? .zero
            await self.cameraSessionService.setRectOfInterest(rect)
        }
    }
    
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
    }
    
    func startCamera() async {
        let availableToRunSession = await self.cameraSessionService.setupCaptureSession()
        let output = await self.cameraSessionService.metadataOutput
        output?.setMetadataObjectsDelegate(self, queue: .main)
        
        if availableToRunSession == true {
            await self.addPreviewLayer()
        } else {
            self.presenter.failedToSetupCaptureSession()
        }
    }
    
    func addPreviewLayer() async {
        guard let previewLayer = await self.cameraSessionService.getPreviewLayer() else { return }
        
        previewLayer.frame = captureSessionContainerView.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        captureSessionContainerView.layer.addSublayer(previewLayer)
        self.previewLayer = previewLayer
        updateRectOfInterest()
    }
}

private actor CameraSessionService {
    
    private var captureSession: AVCaptureSession?
    private var videoCaptureDevice: AVCaptureDevice?
    private var videoInput: AVCaptureDeviceInput?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private(set) var metadataOutput: AVCaptureMetadataOutput?

    var isSessionSet: Bool { captureSession != nil }
    var isSessionRunning: Bool { captureSession?.isRunning == true }

    func setupCaptureSession() -> Bool {
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .hd1920x1080
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return false }
        self.videoCaptureDevice = videoCaptureDevice
        
        do {
            let videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            if (captureSession.canAddInput(videoInput)) {
                captureSession.addInput(videoInput)
            } else {
                return false
            }
            
            let metadataOutput = AVCaptureMetadataOutput()
            if (captureSession.canAddOutput(metadataOutput)) {
                captureSession.addOutput(metadataOutput)
                metadataOutput.metadataObjectTypes = metadataOutput.availableMetadataObjectTypes
            } else {
                return false
            }
            
            self.captureSession = captureSession
            self.videoInput = videoInput
            self.metadataOutput = metadataOutput
            
            return true
        } catch {
            return false
        }
    }
  
    func startCaptureSession() {
        guard !isSessionRunning else { return }
        
        captureSession?.startRunning()
    }
    
    func stopCaptureSession() {
        guard isSessionRunning else { return }
        
        captureSession?.stopRunning()
    }
    
    func getPreviewLayer() -> AVCaptureVideoPreviewLayer? {
        if let previewLayer = self.previewLayer {
            return previewLayer
        }
        guard let captureSession = self.captureSession else { return nil }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.previewLayer = previewLayer
        return previewLayer
    }
    
    func setRectOfInterest(_ rect: CGRect) {
        metadataOutput?.rectOfInterest = rect
    }
}

extension QRScannerViewController {
    enum State {
        case askingForPermissions
        case scanning
        case permissionsDenied
        case cameraNotAvailable
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
