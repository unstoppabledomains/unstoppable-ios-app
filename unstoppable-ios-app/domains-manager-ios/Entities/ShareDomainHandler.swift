//
//  ShareDomainHandler.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.10.2022.
//

import UIKit

final class ShareDomainHandler: NSObject {
    
    private weak var view: BaseViewControllerProtocol?
    private var imageSavedCallback: EmptyCallback?
    let domain: DomainDisplayInfo
    private var selectedStyleName: String?
    
    init(domain: DomainDisplayInfo) {
        self.domain = domain
        super.init()
        loadQRCode()
    }
   
    func getDomainQRImage() async -> UIImage? {
        guard let url = domain.qrCodeURL else { return nil }
        
        return await appContext.imageLoadingService.loadImage(from: .qrCode(url: url,
                                                                            options: [.withLogo]),
                                                              downsampleDescription: nil)
    }
    
    func getDomainQRImageToShare() async -> UIImage? {
        guard let url = domain.qrCodeURL else { return nil }
        
        return await appContext.imageLoadingService.loadImage(from: .qrCode(url: url,
                                                                            options: []),
                                                              downsampleDescription: nil)
    }
    
    func shareDomainInfo(in view: BaseViewControllerProtocol,
                         analyticsLogger: ViewAnalyticsLogger,
                         imageSavedCallback: EmptyCallback? = nil) {
        self.imageSavedCallback = imageSavedCallback
        self.view = view
        Task {
            guard let qrImage = await getDomainQRImageToShare() else { return }
            
            let shareSelectionResult = await appContext.pullUpViewService.showShareDomainPullUp(domain: domain,
                                                                                                qrCodeImage: qrImage,
                                                                                                in: view)
            UDVibration.buttonTap.vibrate()
            switch shareSelectionResult {
            case .cancel:
                logButtonPressedAnalyticEvent(button: .cancel, in: analyticsLogger)
                return
            case .shareLink:
                logButtonPressedAnalyticEvent(button: .shareLink, in: analyticsLogger)
                
                await view.dismissPullUpMenu()
                let domainPreviewView = await SocialsDomainImagePreviewView()
                let avatarImage = await appContext.imageLoadingService.loadImage(from: .domain(domain),
                                                                                 downsampleDescription: nil) ?? .domainSharePlaceholder
                await domainPreviewView.setPreview(with: .init(domain: domain,
                                                               originalDomainImage: avatarImage,
                                                               qrImage: qrImage))
                
                var shareImage: UIImage?
                let imageSize: CGFloat = 1024
                
                if let image = await domainPreviewView.finalImage(),
                   let downsampledImage = appContext.imageLoadingService.downsample(image: image,
                                                                                    downsampleDescription: .init(size: CGSize(width: imageSize,
                                                                                                                              height: imageSize),
                                                                                                                 scale: 2)) {
                    shareImage = downsampledImage
                }
                
                await shareLink(image: shareImage, in: view)
            case .saveAsImage:
                logButtonPressedAnalyticEvent(button: .saveAsImage, in: analyticsLogger)
                let originalImage = (await appContext.imageLoadingService.loadImage(from: .domain(domain),
                                                                                    downsampleDescription: nil)) ?? .domainSharePlaceholder
                
                let description = SaveDomainImageDescription(domain: domain,
                                                             originalDomainImage: originalImage,
                                                             qrImage: qrImage)
                if let result = try? await appContext.pullUpViewService.showSaveDomainImageTypePullUp(description: description,
                                                                                                      in: view) {
                    selectedStyleName = result.style.name
                    await view.dismissPullUpMenu()
                    saveImage(result.image)
                }
            case .shareViaNFC:
                logButtonPressedAnalyticEvent(button: .createNFCTag, in: analyticsLogger)

                await view.dismissPullUpMenu()
                do {
                    guard let url = String.Links.domainProfilePage(domainName: domain.name).url else {
                        Debugger.printFailure("Failed to get url from domain profile to write NFC tag", critical: true)
                        return
                    }
                    try await NFCService.shared.writeURL(url)
                } catch {
                    Debugger.printFailure("Failed to write NFC tag", critical: false)
                }
            }
        }
    }
}

// MARK: - Private methods
private extension ShareDomainHandler {
    func loadQRCode() {
        Task.detached(priority: .high) { [weak self] in
            _ = await self?.getDomainQRImage()
        }
        
        Task.detached(priority: .background) { [weak self] in
            _ = await self?.getDomainQRImageToShare()
        }
    }
    
    @MainActor
    func shareLink(image: UIImage?, in view: UIViewController) {
        var items: [Any] = []
        if let image {
            items.append(image)
        }
        view.shareDomainProfile(domainName: domain.name, additionalItems: items)
    }
    
    func saveImage(_ image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(handleImageSavingWith(image:error:contextInfo:)), nil)
    }
    
    @objc func handleImageSavingWith(image: UIImage, error: Error?, contextInfo: UnsafeRawPointer) {
        Task { @MainActor in
            if let error = error {
                view?.showAlertWith(error: error, handler: nil)
            } else {
                Vibration.success.vibrate()
                imageSavedCallback?()
                if let selectedStyleName {
                    appContext.toastMessageService.showToast(.itemSaved(name: selectedStyleName), isSticky: false)
                }
                AppReviewService.shared.appReviewEventDidOccurs(event: .didSaveProfileImage)
            }
        }
    }
    
    func logButtonPressedAnalyticEvent(button: Analytics.Button,
                                       in analyticsLogger: ViewAnalyticsLogger) {
        analyticsLogger.logButtonPressedAnalyticEvents(button: button,
                                                       parameters: [.domainName: domain.name])
    }
}
