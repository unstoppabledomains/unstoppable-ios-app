//
//  UIImage.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 08.04.2022.
//

import UIKit
import Accelerate.vImage

extension UIImage {
    static let copyToClipboardIcon = UIImage(named: "copyIcon")!
    static let faceIdIcon = UIImage(named: "protectFaceIDIcon")!
    static let touchIdIcon = UIImage(named: "protectTouchIDIcon")!
    static let passcodeIcon = UIImage(named: "passcodeIcon")!
    static let warningIconLarge = UIImage(named: "statusWarningIcon")!
    static let warningIcon = UIImage(named: "warningIcon")!
    static let ethereumIcon = UIImage(named: "ethereumIcon")!
    static let polygonIcon = UIImage(named: "polygonIcon")!
    static let zilIcon = UIImage(named: "zilIcon")!
    static let externalWalletIndicator = UIImage(named: "externalWalletIndicator")!
    static let cloudIcon = UIImage(named: "cloudIcon")!
    static let checkCircleWhite = UIImage(named: "checkCircleWhite")!
    static let checkCircle = UIImage(named: "checkCircle")!
    static let connectionOffIcon = UIImage(named: "connectionOffIcon")!
    static let shareIcon = UIImage(named: "shareIcon")!
    static let shareIconSmall = UIImage(named: "shareIconSmall")!
    static let penIcon = UIImage(named: "penIcon")!
    static let dotsCircleIcon = UIImage(named: "dotsCircleIcon")!
    static let udLogo = UIImage(named: "udLogo")!
    static let walletBTCIcon = UIImage(named: "walletBTCIcon")!
    static let stopIcon = UIImage(named: "stopIcon")!
    static let infoIcon16 = UIImage(named: "infoIcon16")!
    static let infoIcon12 = UIImage(named: "infoIcon12")!
    static let iconStar24 = UIImage(named: "iconStar24")!

    static let crossWhite = UIImage(named: "crossWhite")!
    static let refreshIcon = UIImage(named: "refreshIcon")!
    static let plusCircle = UIImage(named: "plusCircle")!
    static let minusCircle = UIImage(named: "minusCircle")!
    static let dotsIcon = UIImage(named: "dotsIcon")!
    static let gearshape = UIImage(named: "gearshape")!
    static let appleIcon = UIImage(named: "appleIcon")!
    static let gasFeeIcon = UIImage(named: "gasFeeIcon")!
    static let sparklesIcon = UIImage(named: "sparklesIcon")!
    static let chevronDown = UIImage(named: "newChevronDown")!
    static let chevronUp = UIImage(named: "chevronUp")!
    static let domainsProfileIcon = UIImage(named: "domainsProfileIcon")!
    static let magicWandIcon = UIImage(named: "magicWandIcon")!
    static let widgetIcon = UIImage(named: "widgetIcon")!
    static let searchIcon = UIImage(named: "searchIcon")!
    static let ethBGLarge = UIImage(named: "ethBGLarge")!
    static let maticBGLarge = UIImage(named: "maticBGLarge")!
    static let ethBGSmall = UIImage(named: "ethBGSmall")!
    static let maticBGSmall = UIImage(named: "maticBGSmall")!
    static let checkBadge = UIImage(named: "checkBadge")!
    static let grimaseIcon = UIImage(named: "grimaseIcon")!
    static let cloudOfflineIcon = UIImage(named: "cloudOfflineIcon")!
    static let chainIcon = UIImage(named: "chainIcon")!
    static let checkIcon = UIImage(named: "checkIcon")!
    static let bellIcon = UIImage(named: "bellIcon")!
    static let repairIcon = UIImage(named: "repairIcon")!
    static let downloadIcon = UIImage(named: "downloadIcon")!
    static let searchClearIcon = UIImage(named: "searchClearIcon")!
    static let cancelCircleIcon = UIImage(named: "cancelCircleIcon")!
    static let vaultIcon = UIImage(named: "vaultIcon")!
    static let smileIcon = UIImage(named: "smileIcon")!
    static let tapIcon = UIImage(named: "tapIcon")!
    static let walletIcon = UIImage(named: "walletIcon")!
    static let udWalletListIcon = UIImage(named: "udWalletListIcon")!
    static let recoveryPhraseIcon = UIImage(named: "recoveryPhraseIcon")!
    static let plusIconSmall = UIImage(named: "plusIconSmall")!
    static let plusIconNav = UIImage(named: "plusIconNav")!
    static let domainsListIcon = UIImage(named: "domainsListIcon")!
    static let cartIcon = UIImage(named: "cartIcon")!
    static let navArrowLeft = UIImage(named: "navArrowLeft")!
    static let cancelIcon = UIImage(named: "cancelIcon")!
    static let domainSharePlaceholder = UIImage(named: "domainSharePlaceholder")!
    static let walletOpen = UIImage(named: "walletOpen")!
    static let reverseResolutionCircleSign = UIImage(named: "reverseResolutionCircleSign")!
    static let reverseResolutionArrows = UIImage(named: "reverseResolutionArrows")!
    static let reverseResolutionArrows12 = UIImage(named: "reverseResolutionArrows12")!
    static let homeDomainInfoVisualisation = UIImage(named: "homeDomainInfoVisualisation")!
    static let trashIcon = UIImage(named: "trashIcon")!
    static let settingsIconAppearance = UIImage(named: "settingsIconAppearance")!
    static let infoIcon = UIImage(named: "settingsIconPrivacy")!
    static let arrowTopRight = UIImage(named: "arrowTopRight")!
    static let framesIcon = UIImage(named: "framesIcon")!
    static let framesIcon16 = UIImage(named: "framesIcon16")!
    static let framesIcon20 = UIImage(named: "framesIcon20")!
    static let scanQRIcon = UIImage(named: "scanQRIcon")!
    static let scanQRIcon16 = UIImage(named: "scanQRIcon16")!
    static let scanQRIcon20 = UIImage(named: "scanQRIcon20")!
    static let web3ProfileIllustration = UIImage(named: "web3ProfileIllustration")!
    static let web3ProfileIllustrationLarge = UIImage(named: "web3ProfileIllustrationLarge")!
    static let web3ProfileIllustrationLargeiPhoneSE = UIImage(named: "web3ProfileIllustrationLargeiPhoneSE")!
    static let profileAccessIllustration = UIImage(named: "profileAccessIllustration")!
    static let profileAccessIllustrationLarge = UIImage(named: "profileAccessIllustrationLarge")!
    static let profileAccessIllustrationLargeiPhoneSE = UIImage(named: "profileAccessIllustrationLargeiPhoneSE")!
    static let avatarsIcon16 = UIImage(named: "avatarsIcon16")!
    static let avatarsIcon20 = UIImage(named: "avatarsIcon20")!
    static let avatarsIcon24 = UIImage(named: "avatarsIcon24")!
    static let avatarsIcon32 = UIImage(named: "avatarsIcon32")!
    static let badgeIcon20 = UIImage(named: "badgeIcon20")!
    static let planetIcon20 = UIImage(named: "planetIcon20")!
    static let reputationIcon20 = UIImage(named: "reputationIcon20")!
    static let rewardsIcon20 = UIImage(named: "rewardsIcon20")!
    static let rocketIcon20 = UIImage(named: "rocketIcon20")!
    static let walletBTCIcon20 = UIImage(named: "walletBTCIcon20")!
    static let refreshArrow20 = UIImage(named: "refreshArrow20")!
    static let refreshArrow24 = UIImage(named: "refreshArrow24")!
    static let mailIcon24 = UIImage(named: "mailIcon24")!
    static let googleIcon24 = UIImage(named: "googleIcon24")!
    static let locationIcon24 = UIImage(named: "locationIcon24")!
    static let networkArrowIcon24 = UIImage(named: "networkArrowIcon24")!
    static let openQuoteIcon24 = UIImage(named: "openQuoteIcon24")!
    static let moduleIcon24 = UIImage(named: "moduleIcon24")!
    static let badgesStarIcon24 = UIImage(named: "badgesStarIcon24")!
    static let udBadgeLogo = UIImage(named: "udBadgeLogo")!
    static let smileyNegative = UIImage(named: "smileyNegative")!
    static let alertCircle = UIImage(named: "alertCircle")!
    static let hammerWrenchIcon24 = UIImage(named: "hammerWrenchIcon24")!
    static let showcaseDomainProfileIllustration = UIImage(named: "showcaseDomainProfileIllustration")!
    static let arrowRight = UIImage(named: "arrowRight")!
    static let timeIcon24 = UIImage(named: "timeIcon24")!
    static let dragIcon24 = UIImage(named: "dragIcon24")!
    static let parkingIcon24 = UIImage(named: "parkingIcon24")!
    static let logOutIcon24 = UIImage(named: "logOutIcon24")!
    static let connectedAppNetworksInfoIllustration = UIImage(named: "connectedAppNetworksInfoIllustration")!
    static let nfcIcon20 = UIImage(named: "nfcIcon20")!
    static let giftBoxIcon20 = UIImage(named: "giftBoxIcon20")!
    static let helpCircleIcon24 = UIImage(named: "helpCircleIcon24")!
    static let messageCircleIcon24 = UIImage(named: "messageCircleIcon24")!
    static let plusIcon18 = UIImage(named: "plusIcon18")!
    static let arrowUp24 = UIImage(named: "arrowUp24")!
    static let chatRequestsIcon = UIImage(named: "chatRequestsIcon")!
    static let newMessageIcon = UIImage(named: "newMessageIcon")!
    static let trashIcon16 = UIImage(named: "trashIcon16")!
    static let alertOctagon24 = UIImage(named: "alertOctagon24")!
    static let infoEmptyIcon24 = UIImage(named: "infoEmptyIcon24")!
    static let docsIcon24 = UIImage(named: "docsIcon24")!
    static let helpIcon24 = UIImage(named: "helpIcon24")!
    static let followerGrayPlaceholder = UIImage(named: "followerGrayPlaceholder")!
    static let cellChevron = UIImage(named: "cellChevron")!
    static let udCartLogoRaster = UIImage(named: "udCartLogoRaster")!
    static let chooseRRDomainIllustration = UIImage(named: "chooseRRDomainIllustration")!
    static let udBlueGrayIcon = UIImage(named: "udBlueGrayIcon")!
    static let check = UIImage(named: "check")!
    static let statsIcon = UIImage(named: "statsIcon")!
    static let sparkleIcon = UIImage(named: "sparkleIcon")!
    static let chevronRight = UIImage(named: "chevronRight")!
    static let tagsCashIcon = UIImage(named: "tagsCashIcon")!
    static let usaFlagIcon = UIImage(named: "usaFlagIcon")!
    static let tagIcon = UIImage(named: "tagIcon")!
    static let tapSingleIcon = UIImage(named: "tapSingleIcon")!
    
    static let twitterIcon24 = UIImage(named: "twitterIcon24")!
    static let discordIcon24 = UIImage(named: "discordIcon24")!
    static let telegramIcon24 = UIImage(named: "telegramIcon24")!
    static let redditIcon24 = UIImage(named: "redditIcon24")!
    static let youTubeIcon24 = UIImage(named: "youTubeIcon24")!
    static let linkedInIcon24 = UIImage(named: "linkedInIcon24")!
    static let gitHubIcon24 = UIImage(named: "gitHubIcon24")!
    static let twitterOriginalIcon = UIImage(named: "twitterOriginalIcon")!
    static let discordOriginalIcon = UIImage(named: "discordOriginalIcon")!
    static let telegramOriginalIcon = UIImage(named: "telegramOriginalIcon")!
    static let redditOriginalIcon = UIImage(named: "redditOriginalIcon")!
    static let youTubeOriginalIcon = UIImage(named: "youTubeOriginalIcon")!
    static let linkedInOriginalIcon = UIImage(named: "linkedInIcon24")!
    static let gitHubOriginalIcon = UIImage(named: "gitHubIcon24")!

    
    // System SF symbols
    static let personCropCircle = UIImage(systemName: "person.crop.circle")
    static let personCircle = UIImage(systemName: "person.circle")!
    static let arrowUpRightCircle = UIImage(systemName: "arrowshape.turn.up.right.circle")
    static let arrowUpRight = UIImage(systemName: "arrowshape.turn.up.right")!
    static let safari = UIImage(systemName: "safari")!
    static let chevronLeft = UIImage(systemName: "chevron.left")
    static let systemChevronRight = UIImage(systemName: "chevron.right")
    static let systemMinusCircle = UIImage(systemName: "minus.circle")!
    static let systemMultiplyCircle = UIImage(systemName: "multiply.circle")!
    static let arrowRightArrowLeft = UIImage(systemName: "arrow.right.arrow.left")!
    static let systemPhotoRectangle = UIImage(systemName: "photo.on.rectangle")!
    static let systemDocOnDoc = UIImage(systemName: "doc.on.doc")!
    static let systemQuestionmarkCircle = UIImage(systemName: "questionmark.circle")!
    static let systemTrash = UIImage(systemName: "trash")!
    static let systemSquareAndPencil = UIImage(systemName: "square.and.pencil")!
    static let systemPlusMagnifyingGlass = UIImage(systemName: "plus.magnifyingglass")!
    static let systemHexagonRightHalfFilled = UIImage(systemName: "hexagon.righthalf.filled")!
    static let systemLock = UIImage(systemName: "lock")!
    static let systemGlobe = UIImage(systemName: "globe")!
    static let systemChevronUpDown = UIImage(systemName: "chevron.up.chevron.down")!
    static let systemArrowTurnUpRight = UIImage(systemName: "arrow.turn.up.right")!
    static let systemCamera = UIImage(systemName: "camera")!
    static let systemRectangleArrowRight = UIImage(systemName: "rectangle.portrait.and.arrow.right")!
    static let systemCircle = UIImage(systemName: "circle")!
    static let systemCheckmarkCircleFill = UIImage(systemName: "checkmark.circle.fill")!
    
}

extension UIImage {
    func transparentImage() -> UIImage {
        if let cgImage = self.cgImage,
           let imageWOBackground = cgImage.copy(maskingColorComponents: [222, 255, 222, 255, 222, 255]) {
            let templateImage = UIImage(cgImage: imageWOBackground).withRenderingMode(.alwaysTemplate)
            return templateImage
        }
        Debugger.printFailure("Failed to prepare QR Code image", critical: true)
        return self
    }
    
    func templateImageOfSize(_ size: CGSize) -> UIImage {
        scalePreservingAspectRatio(targetSize: size)
            .withRenderingMode(.alwaysTemplate)
    }

    class func getNetworkLargeIcon(by blockchainType: BlockchainType) -> UIImage? {
        switch blockchainType {
        case .Ethereum:
            return .ethBGLarge
        case .Matic:
            return .maticBGLarge
        case .Zilliqa:
            Debugger.printFailure("Trying to connect unsupported Zilliqa network", critical: true)
            return nil
        }
    }
    
    class func getNetworkSmallIcon(by blockchainType: BlockchainType) -> UIImage? {
        switch blockchainType {
        case .Ethereum:
            return .ethBGSmall
        case .Matic:
            return .maticBGSmall
        case .Zilliqa:
            Debugger.printFailure("Trying to connect unsupported Zilliqa network", critical: true)
            return nil
        }
    }
    
    func cropTo(rect: CGRect) -> UIImage? {
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        
        let drawRect = CGRect(x: -rect.origin.x, y: -rect.origin.y,
                              width: size.width, height: size.height)
        
        context?.clip(to: CGRect(x: 0, y: 0,
                                 width: rect.size.width, height: rect.size.height))
        
        draw(in: drawRect)
        
        let subImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        return subImage
    }
    
    func aspectCropToSquare() -> UIImage? {
        let width = size.width
        let height = size.height
        
        if width == height {
            return self
        }
        
        if width > height {
            let croppingRect = CGRect(x: (width - height) / 2,
                                      y: 0,
                                      width: height,
                                      height: height)
            return cropTo(rect: croppingRect)
        } else {
            let croppingRect = CGRect(x: 0,
                                      y: (height - width) / 2,
                                      width: width,
                                      height: width)
            return cropTo(rect: croppingRect)
        }
    }
    
    @MainActor
    func croppedImageTo(size: CGSize,
                        modificationBlock: (UIImageView)->()) -> UIImage {
        let imageView = UIImageView(frame: CGRect(origin: .zero,
                                                  size: size))
        imageView.image = self
        imageView.clipsToBounds = true
        modificationBlock(imageView)
        
        return imageView.renderedImage()
    }

    @MainActor
    func circleCroppedImage(size: CGFloat) -> UIImage {
        return croppedImageTo(size: .init(width: size,
                                          height: size)) { imageView in
            imageView.contentMode = .scaleAspectFill
            imageView.layer.cornerRadius = size / 2
            imageView.layer.borderWidth = 1
            imageView.layer.borderColor = UIColor.borderSubtle.cgColor
        }
    }
    
    func resized(to maxResolution: CGFloat) -> UIImage? {
        let size = self.size
        let largestSide = max(size.width, size.height)
        if largestSide <= maxResolution {
            return self
        }
        let scale = maxResolution / largestSide
        let newWidth = size.width * scale
        let newHeight = size.height * scale
        let newSize = CGSize(width: newWidth, height: newHeight)
        
        let image = self.gifImageDownsampled(to: newSize,
                                             scale: 1)
        
        return image
    }
    
    func scalePreservingAspectRatio(targetSize: CGSize) -> UIImage {
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        let scaleFactor = min(widthRatio, heightRatio)
        let scaledImageSize = CGSize(width: size.width * scaleFactor, height: size.height * scaleFactor)
        let renderer = UIGraphicsImageRenderer(size: scaledImageSize)
        let scaledImage = renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: scaledImageSize))
        }
        
        return scaledImage
    }
}

extension UIImage {
    var dataToUpload: Data? { try? self.gifDataRepresentation(quality: 0.7) }
    var base64String: String? { dataToUpload?.base64EncodedString() }
}

extension UIImage {
    static func from(base64String: String) async -> UIImage? {
        guard let dataDecoded = Data(base64Encoded: base64String, options: .ignoreUnknownCharacters) else { return nil }

        return await createWith(anyData: dataDecoded)
    }
    
    static func createWith(anyData data: Data) async -> UIImage? {
        if let gif = await GIFAnimationsService.shared.createGIFImageWithData(data) {
            return gif
        } else if let image = UIImage(data: data) {
            return image
        } else if let svg = UIImage.from(svgData: data) {
            return svg
        }
        return nil
    }
}
