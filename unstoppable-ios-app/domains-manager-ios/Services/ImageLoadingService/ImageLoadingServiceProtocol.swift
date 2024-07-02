//
//  ImageLoadingServiceProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 01.12.2023.
//

import UIKit

protocol ImageLoadingServiceProtocol {
    func loadImage(from source: ImageSource, downsampleDescription: DownsampleDescription?) async -> UIImage?
    func cachedImage(for source: ImageSource, downsampleDescription: DownsampleDescription?) -> UIImage?
    func downsample(image: UIImage, downsampleDescription: DownsampleDescription) -> UIImage?
    func storeImage(_ image: UIImage, for source: ImageSource) async
    func getStoredImage(for source: ImageSource) async -> UIImage?
    func clearCache() async
    func clearStoredImages() async
}

// MARK: - DownsampleDescription
struct DownsampleDescription {
    let size: CGSize
    let scale: CGFloat
    var cacheKey: String { "\(size.width)x\(size.height)x\(scale)" }
    
    init(size: CGSize, scale: CGFloat) {
        self.size = size
        self.scale = scale
    }
    
    init(maxSize: CGFloat, scale: CGFloat = 1) {
        self.init(size: .init(width: maxSize, height: maxSize), scale: scale)
    }
    
    @MainActor
    static let max: DownsampleDescription = .init(maxSize: Constants.downloadedImageMaxSize, scale: SceneDelegate.shared?.window?.screen.scale ?? 2)
    static let mid: DownsampleDescription = .init(maxSize: 256)
    static let icon: DownsampleDescription = .init(maxSize: Constants.downloadedIconMaxSize)
}

enum ImageSource: Sendable {
    case url(_ url: URL, maxSize: CGFloat? = nil)
    case initials(_ name: String, size: InitialsView.InitialsSize, style: InitialsView.Style)
    case domain(_ domainItem: DomainDisplayInfo)
    case domainPFPSource(_ domainPFPSource: DomainPFPInfo.PFPSource)
    case domainNameInitials(_ domainName: String, size: InitialsView.InitialsSize)
    case domainInitials(_ domainItem: DomainDisplayInfo, size: InitialsView.InitialsSize)
    case domainItemOrInitials(_ domainItem: DomainDisplayInfo, size: InitialsView.InitialsSize)
    case walletDomain(_ walletAddress: HexAddress)
    case currency(_ currency: CoinRecord, size: InitialsView.InitialsSize, style: InitialsView.Style)
    case currencyTicker(_ ticker: String, size: InitialsView.InitialsSize, style: InitialsView.Style)
    case wcApp(_ appInfo: WalletConnectServiceV2.WCServiceAppInfo, size: InitialsView.InitialsSize)
    case connectedApp(_ connectedApp: any UnifiedConnectAppInfoProtocol, size: InitialsView.InitialsSize)
    case qrCode(url: URL, options: [QRCodeService.Options])
    case messagingUserPFPOrInitials(_ userInfo: MessagingChatUserDisplayInfo, size: InitialsView.InitialsSize)
    
    var key: String {
        switch self {
        case .url(let url, _):
            return url.absoluteString
        case .initials(let name, let initialsSize, let style):
            var initials = Constants.defaultInitials
            if let firstChar = name.first {
                initials = firstChar.uppercased()
            }
            return initials + "_\(initialsSize.rawValue)_\(style.rawValue)"
        case .domain(let domainItem):
            return ImageSource.domainPFPSource(domainItem.pfpSource).key
        case .domainPFPSource(let pfpSource):
            return pfpSource.value
        case .domainNameInitials(let domainName, let size):
            return ImageSource.initials(domainName, size: size, style: .accent).key
        case .domainInitials(let domainItem, let size):
            return ImageSource.domainNameInitials(domainItem.name, size: size).key
        case .domainItemOrInitials(let domainItem, let size):
            if domainItem.pfpSource != .none {
                return ImageSource.domain(domainItem).key
            }
            return ImageSource.domainInitials(domainItem, size: size).key
        case .walletDomain(let walletAddress):
            return walletAddress
        case .currency(let currency, let size, let style):
            return ImageSource.currencyTicker(currency.ticker, size: size, style: style).key
        case .currencyTicker(let ticker, let size, let style):
            return ticker + "_\(size.rawValue)_\(style.rawValue)"
        case .wcApp(let appInfo, let size):
            return appInfo.getDisplayName() + "_\(size.rawValue)"
        case .connectedApp(let appInfo, let size):
            return appInfo.displayName + "_\(size.rawValue)"
        case .qrCode(let url, let options):
            let urlKey = ImageSource.url(url).key
            let optionsKey = options.sorted(by: { $0.rawValue < $1.rawValue }).map({ "\($0.rawValue)" }).joined(separator: "_")
            return urlKey + "_" + optionsKey
        case .messagingUserPFPOrInitials(let userInfo, _):
            return "messaging_" + userInfo.wallet.normalized
        }
    }
    
    func keyFor(downsampleDescription: DownsampleDescription?) -> String {
        if let downsampleDescription {
            return self.key + "_" + downsampleDescription.cacheKey
        }
        return self.key
    }
}
