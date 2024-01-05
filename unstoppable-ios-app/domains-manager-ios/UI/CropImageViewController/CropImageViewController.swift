//
//  CropImageViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 20.10.2022.
//

import UIKit

typealias CropImageCallback = (UIImage)->()

final class CropImageViewController: BaseViewController {
    
    @IBOutlet fileprivate weak var overlayView: UIView!
    @IBOutlet fileprivate weak var cropZoneView: UIView!
    @IBOutlet fileprivate weak var scrollView: UIScrollView!
    @IBOutlet fileprivate weak var cancelButton: RaisedTertiaryWhiteButton!
    @IBOutlet fileprivate weak var saveButton: RaisedWhiteButton!
    
    @IBOutlet weak var cropZoneViewAspectRatioAvatarConstraint: NSLayoutConstraint!
    @IBOutlet weak var cropZoneViewAspectRatioPostConstraint: NSLayoutConstraint!
    
    private var imageCroppedCallback: CropImageCallback?
    
    fileprivate var imageView: UIImageView = UIImageView()
    fileprivate var image: UIImage!
    fileprivate var croppingStyle: CroppingStyle = .avatar
    override var analyticsName: Analytics.ViewName { .cropPhoto }
    private var currentFrame: CGRect = .zero
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
    }
   
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if currentFrame != view.frame {
            currentFrame = view.frame
            DispatchQueue.main.async { [weak self] in
                self?.setupOverlayView()
                self?.setupDefaultScrollViewValues()
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        setupCropZoneView()
    }
    
    // MARK: - Initialization methods
    static func instantiate(with image: UIImage, croppingStyle: CroppingStyle) -> CropImageViewController {
        let viewController = CropImageViewController.nibInstance()
        viewController.image = image
        viewController.croppingStyle = croppingStyle
        
        return viewController
    }
    
    static func show(in viewController: UIViewController,
                     with image: UIImage,
                     croppingStyle: CroppingStyle,
                     imageCroppedCallback: @escaping CropImageCallback) {
        let vc = instantiate(with: image, croppingStyle: croppingStyle)
        
        vc.imageCroppedCallback = imageCroppedCallback
        vc.modalPresentationStyle = .fullScreen
        viewController.present(vc, animated: true)
    }
    
}

// MARK: - Actions
fileprivate extension CropImageViewController {
    @IBAction func cancelPressed(_ sender: UIButton) {
        logButtonPressedAnalyticEvents(button: .cancel)
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func savePressed(_ sender: UIButton) {
        logButtonPressedAnalyticEvents(button: .confirm)
        guard let croppedImage = cropImage(image, cropZone: cropZoneView.frame) else {
            showSimpleAlert(title: String.Constants.somethingWentWrong.localized(),
                            body: String.Constants.pleaseTryAgain.localized())
            return
        }
        
        dismiss(animated: true, completion: { [weak self] in
            self?.imageCroppedCallback?(croppedImage)
        })
    }
}

// MARK: - Private methods
fileprivate extension CropImageViewController {
    func setupUI() {
        localizeElements()
        setupScrollView()
    }
    
    func setupCropZoneView() {
        if croppingStyle == .avatar {
            cropZoneViewAspectRatioAvatarConstraint.isActive = true
            cropZoneViewAspectRatioPostConstraint.isActive = false
        } else {
            cropZoneViewAspectRatioAvatarConstraint.isActive = false
            cropZoneViewAspectRatioPostConstraint.isActive = true
        }
        view.setNeedsLayout()
        view.layoutIfNeeded()
    }
    
    func localizeElements() {
        cancelButton.setTitle(String.Constants.cancel.localized(), image: nil)
        saveButton.setTitle(String.Constants.confirm.localized(), image: nil)
    }
    
    func setupScrollView() {
        imageView.contentMode = .scaleAspectFit

        imageView.image = image
        scrollView.contentSize = CGSize.init(width: imageView.frame.width, height: imageView.frame.height)
        scrollView.minimumZoomScale = 1
        scrollView.maximumZoomScale = 5
        scrollView.delegate = self
        scrollView.clipsToBounds = true
        scrollView.addSubview(imageView)
    }

    func setupOverlayView() {
        let path = CGMutablePath()
        
        switch croppingStyle{
        case .avatar:
            let cropeZoneCenter: CGPoint = cropZoneView.center
            let convertedOverlayPoint = cropZoneView.superview?.convert(cropeZoneCenter, to: overlayView) ?? .zero
            path.addArc(center: CGPoint(x: convertedOverlayPoint.x, y: convertedOverlayPoint.y),
                        radius: cropZoneView.frame.width / 2,
                        startAngle: 0.0,
                        endAngle: 2.0 * .pi,
                        clockwise: false)
        case .banner:
            let convertedOverlayCropRect = cropZoneView.superview?.convert(cropZoneView.frame, to: overlayView) ?? .zero
            path.addRect(convertedOverlayCropRect)
        }
     
        path.addRect(CGRect(origin: .zero, size: overlayView.frame.size))
        
        let maskLayer = CAShapeLayer()
        maskLayer.backgroundColor = UIColor.black.cgColor
        maskLayer.path = path
        maskLayer.fillRule = CAShapeLayerFillRule.evenOdd
        
        overlayView.layer.mask = maskLayer
        overlayView.clipsToBounds = true
    }
    
    func setupDefaultScrollViewValues() {
        let imageViewWidth = scrollView.frame.width
        let imageViewHeight = image.size.height / (image.size.width / imageViewWidth)
        imageView.frame = CGRect(x: 0, y: 0, width: imageViewWidth, height: imageViewHeight)
        
        if image.size.width > image.size.height {  // landscape photo
            // if photo height is less then crop zone, we need to scale photo to fix crop zone
            let visibleImageHeight = image.size.height * (imageView.frame.width / image.size.width)
            if visibleImageHeight < cropZoneView.frame.height {
                let multiplier = cropZoneView.frame.height / visibleImageHeight
                scrollView.minimumZoomScale = multiplier
                scrollView.setZoomScale(multiplier, animated: true)
            }
        } else {
            // if photo width is less then crop zone, we need to scale photo to fix crop zone
            let visibleImageWidth = image.size.width * (imageView.frame.height / image.size.height)
            if visibleImageWidth < cropZoneView.frame.width {
                let multiplier = cropZoneView.frame.width / visibleImageWidth
                scrollView.minimumZoomScale = multiplier
                scrollView.setZoomScale(multiplier, animated: true)
            }
        }
        
        var photoHeight = image.size.height / (image.size.width / scrollView.frame.width)
        photoHeight = photoHeight * scrollView.zoomScale
        
        let photoAndCropZoneDiff = (photoHeight - cropZoneView.frame.height) / 2
        let scrollViewAndCropZoneDiff = (photoHeight - scrollView.frame.height) / 2
        let inset = photoAndCropZoneDiff - scrollViewAndCropZoneDiff
        
        scrollView.contentInset = UIEdgeInsets(top: inset, left: 0, bottom: inset, right: 0)
        if photoAndCropZoneDiff > 0 {  // portrait photo
            let y = photoAndCropZoneDiff - inset
            scrollView.contentOffset = CGPoint(x: 0, y: y)
        }
        self.scrollView.setZoomScale(scrollView.zoomScale, animated: false)
    }
    
    func cropImage(_ image: UIImage, cropZone: CGRect) -> UIImage? {
        let fixedImage = image.fixOrientations()
        
        var multiplier: CGFloat = 0
        let photoHeight = image.size.height / (image.size.width / scrollView.frame.width)
        if photoHeight > cropZone.height {
            multiplier = fixedImage.size.width / cropZone.width
        } else {
            multiplier = fixedImage.size.height / cropZone.height
        }
        multiplier /= (scrollView.zoomScale / scrollView.minimumZoomScale)
        
        let originalCropSize = CGSize.init(width: cropZone.size.width * multiplier, height: cropZone.size.height * multiplier)
        
        let offset = scrollView.contentOffset
        let inset = scrollView.contentInset
        
        let topY = offset.y - (-inset.top)     // inset is < 0
        let leftX = offset.x + cropZone.minX
        
        let originalX = leftX * multiplier
        let originalY = topY * multiplier
        
        var originalCropRect = CGRect.init(x: originalX, y: originalY, width: originalCropSize.width, height: originalCropSize.height)
        originalCropRect = originalCropRect.integral
        
        guard let croppedImage = fixedImage.gifImageCropped(to: originalCropRect) else { return nil }
        
        return croppedImage
    }
}

// MARK: - UIScrollViewDelegate
extension CropImageViewController: UIScrollViewDelegate {
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        var photoHeight = image.size.height / (image.size.width / scrollView.frame.width)
        photoHeight = photoHeight * scrollView.zoomScale
        
        let photoAndCropZoneDiff = (photoHeight - cropZoneView.frame.height) / 2
        let scrollViewAndCropZoneDiff = (photoHeight - scrollView.frame.height) / 2
        let inset = photoAndCropZoneDiff - scrollViewAndCropZoneDiff
        
        scrollView.contentInset = UIEdgeInsets(top: inset, left: 0, bottom: inset, right: 0)
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
}

private extension UIImage {
    func fixOrientations() -> UIImage {
        if imageOrientation == .up {
            return self
        }
        
        var transform: CGAffineTransform = CGAffineTransform.identity
        
        switch imageOrientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: size.height)
            transform = transform.rotated(by: CGFloat.pi)
            break
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.rotated(by: CGFloat.pi / 2.0)
            break
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: size.height)
            transform = transform.rotated(by: CGFloat.pi / -2.0)
            break
        case .up, .upMirrored:
            break
        @unknown default:
            break
        }
        switch imageOrientation {
        case .upMirrored, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        case .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x: size.height, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        default:
            break
        }
        
        let ctx: CGContext = CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: self.cgImage!.bitsPerComponent, bytesPerRow: 0, space: self.cgImage!.colorSpace!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        
        ctx.concatenate(transform)
        
        switch imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            ctx.draw(self.cgImage!, in: CGRect(x: 0, y: 0, width: size.height, height: size.width))
        default:
            ctx.draw(self.cgImage!, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
            break
        }
        
        return UIImage(cgImage: ctx.makeImage()!)
    }
}

extension CropImageViewController {
    enum CroppingStyle {
        case avatar, banner
    }
}
