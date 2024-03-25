//
//  QRScannerPreviewView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 25.03.2024.
//

import UIKit
import AVFoundation

final class QRScannerPreviewView: UIView {
    
    private var captureSessionContainerView: UIView!
    private var scannerSightView: QRScannerSightView!
    
    private let cameraSessionService = CameraSessionService()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    var onEvent: ((Event) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setup()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        DispatchQueue.main.async { [weak self] in
            self?.updateRectOfInterest()
        }
    }
   
}

// MARK: - Open methods
extension QRScannerPreviewView {
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
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate
extension QRScannerPreviewView: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        let codes = Array(metadataObjects.lazy.compactMap({ ($0 as? AVMetadataMachineReadableCodeObject)?.stringValue }).filter({ !$0.isEmpty }))
        onEvent?(.didRecognizeQRCodes(codes))
    }
}

// MARK: - Private methods
private extension QRScannerPreviewView {
    func setup() {
        captureSessionContainerView = UIView(frame: bounds)
        captureSessionContainerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(captureSessionContainerView)
        
        scannerSightView = QRScannerSightView(frame: bounds)
        scannerSightView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(scannerSightView)
        
        activate()
    }
    
    func activate() {
        setState(.askingForPermissions)
        
        Task.detached(priority: .low) { [weak self] in
            let isGranted = await appContext.permissionsService.checkPermissionsFor(functionality: .camera)
            
            if isGranted {
                await self?.setState(.scanning)
            } else {
                await self?.setState(.permissionsDenied)
            }
        }
    }
    
    func didTapEnableCameraAccess() {
        Task {
            guard let view = self.findViewController() else { return }
            
            let isGranted = await appContext.permissionsService.askPermissionsFor(functionality: .camera,
                                                                                  in: view,
                                                                                  shouldShowAlertIfNotGranted: false)
            if isGranted {
                setState(.scanning)
                startCaptureSession()
            } else {
                view.openAppSettings()
            }
        }
    }
    
    func updateRectOfInterest()  {
        Task {
            let aimFrame = scannerSightView.aimFrame
            let rect = previewLayer?.metadataOutputRectConverted(fromLayerRect: aimFrame) ?? .zero
            await self.cameraSessionService.setRectOfInterest(rect)
        }
    }
    
    func startCamera() async {
        let availableToRunSession = await self.cameraSessionService.setupCaptureSession()
        let output = await self.cameraSessionService.metadataOutput
        output?.setMetadataObjectsDelegate(self, queue: .main)
        
        if availableToRunSession == true {
            await self.addPreviewLayer()
        } else {
            onEvent?(.didFailToSetupCaptureSession)
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
    
    func setState(_ state: QRScannerState) {
        onEvent?(.didChangeState(state))
        switch state {
        case .scanning:
            firstSubviewOfType(QRScannerPermissionsView.self)?.removeFromSuperview()
            scannerSightView.setBlurHidden(false)
        case .askingForPermissions:
            scannerSightView.setBlurHidden(true)
        case .permissionsDenied, .cameraNotAvailable:
            let permissionsView = QRScannerPermissionsView()
            permissionsView.embedInSuperView(self)
            permissionsView.enableCameraButtonPressedCallback = { [weak self] in
                self?.didTapEnableCameraAccess()
            }
            if state == .cameraNotAvailable {
                permissionsView.setCameraNotAvailable()
            }
            bringSubviewToFront(permissionsView)
        }
    }
}

extension QRScannerPreviewView {
    enum Event {
        case didChangeState(QRScannerState)
        case didRecognizeQRCodes([String])
        case didFailToSetupCaptureSession
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
