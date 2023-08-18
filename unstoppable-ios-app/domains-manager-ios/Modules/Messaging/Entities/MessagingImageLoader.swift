//
//  MessagingImageLoader.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 29.06.2023.
//

import UIKit

@MainActor
struct MessagingImageLoader {
    static func buildImageForGroupChatMembers(_ groupChatMembers: [MessagingChatUserDisplayInfo],
                                              iconSize: CGFloat) async -> UIImage? {
        guard !groupChatMembers.isEmpty else { return nil }
        
        let containerView = UIView(frame: CGRect(origin: .zero, size: .square(size: iconSize)))
        containerView.backgroundColor = .clear
        
        let proportion: CGFloat = 12 / 20
        let imageSize = iconSize * proportion
        func buildImageViewWith(image: UIImage?) -> UIImageView {
            let imageView = UIImageView(frame: CGRect(origin: .zero,
                                                      size: .square(size: imageSize)))
            imageView.image = image
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.layer.cornerRadius = imageSize / 2
            imageView.layer.borderWidth = 1 * proportion
            imageView.borderColor = .white
            
            return imageView
        }
        
        if groupChatMembers.count == 1 {
            return await getIconForUserInfo(groupChatMembers[0])
        }
        let image1 = await getIconForUserInfo(groupChatMembers[0])
        let image2 = await getIconForUserInfo(groupChatMembers[1])
        let imageView1 = buildImageViewWith(image: image1)
        let imageView2 = buildImageViewWith(image: image2)
        containerView.addSubview(imageView1)
        containerView.addSubview(imageView2)
        
        if groupChatMembers.count == 2 {
            imageView1.frame.origin = CGPoint(x: 0, y: iconSize / 5)
            imageView2.frame.origin = CGPoint(x: iconSize / 2.5, y: iconSize / 5)
        } else {
            let image3 = await getIconForUserInfo(groupChatMembers[2])
            let imageView3 = buildImageViewWith(image: image3)
            containerView.addSubview(imageView3)
            
            imageView1.frame.origin = CGPoint(x: 0, y: 0)
            imageView2.frame.origin = CGPoint(x: iconSize / 2.5, y: iconSize / 5)
            imageView3.frame.origin = CGPoint(x: iconSize / 10, y: iconSize / 2.5)
        }
        
        return containerView.renderedImage()
    }
    
    static func getIconForUserInfo(_ userInfo: MessagingChatUserDisplayInfo) async -> UIImage? {
        if let pfpURL = userInfo.pfpURL {
            return await appContext.imageLoadingService.loadImage(from: .url(pfpURL), downsampleDescription: nil)
        } else if let domainName = userInfo.domainName {
            return await getIconImageFor(domainName: domainName)
        }
        return await getIconForWalletAddress(userInfo.wallet)
    }
    
    static func getIconImageFor(domainName: String) async -> UIImage? {
        let pfpInfo = await appContext.udDomainsService.loadPFP(for: domainName)
        if let pfpInfo,
           let image = await appContext.imageLoadingService.loadImage(from: .domainPFPSource(pfpInfo.source),
                                                                      downsampleDescription: nil) {
            return image
        } else if domainName.isValidDomainNameForMessagingSearch(),
                  let rrInfo = try? await NetworkService().fetchGlobalReverseResolution(for: domainName.lowercased()),
                  let pfpURL = rrInfo.pfpURLToUse {
            
            let image = await appContext.imageLoadingService.loadImage(from: .url(pfpURL),
                                                                       downsampleDescription: nil)
            return image
        } else {
            return await getIconWithInitialsFor(name: domainName)
        }
    }
    
    static func getIconForWalletAddress(_ walletAddress: HexAddress) async -> UIImage? {
        await getIconWithInitialsFor(name: walletAddress.droppedHexPrefix)
    }
    
    static func getIconForChannel(_ channel: MessagingNewsChannel) async -> UIImage? {
        if let image = await appContext.imageLoadingService.loadImage(from: .url(channel.icon),
                                                                      downsampleDescription: nil) {
            return image
        } else {
            return await MessagingImageLoader.getIconWithInitialsFor(name: channel.name)
        }
    }
    
    static private func getIconWithInitialsFor(name: String) async -> UIImage? {
        await appContext.imageLoadingService.loadImage(from: .initials(name,
                                                                       size: .default,
                                                                       style: .accent),
                                                       downsampleDescription: nil)
    }
}
