//
//  DomainProfileValidator.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 28.11.2022.
//

import UIKit

protocol DomainProfileSignatureValidator {
    func isAbleToLoadProfile(of domain: DomainDisplayInfo, walletInfo: WalletDisplayInfo) -> Bool
    func askToSignExternalWalletProfileSignature(for domain: DomainDisplayInfo, walletInfo: WalletDisplayInfo, in view: UIViewController) async -> AsyncStream<DomainProfileSignExternalWalletViewPresenter.ResultAction>
    @MainActor
    func isProfileSignatureAvailable(for domain: DomainDisplayInfo, walletInfo: WalletDisplayInfo, in view: UIViewController) async -> Bool
}

extension DomainProfileSignatureValidator {
    
    func isAbleToLoadProfile(of domain: DomainDisplayInfo, walletInfo: WalletDisplayInfo) -> Bool {
        switch walletInfo.source {
        case .external:
            guard !appContext.persistedProfileSignaturesStorage
                .hasValidSignature(for: domain.name) else {
                return true
            }
            
            return false
        case .imported, .locallyGenerated:
            return true
        }
    }
    
    func askToSignExternalWalletProfileSignature(for domain: DomainDisplayInfo, walletInfo: WalletDisplayInfo, in view: UIViewController) async -> AsyncStream<DomainProfileSignExternalWalletViewPresenter.ResultAction> {
        let isOnChainAvatar: Bool
        
        switch domain.pfpSource {
        case .nft:
            isOnChainAvatar = true
        case .nonNFT, .none:
            isOnChainAvatar = false
        }
        let avatarImage = await appContext.imageLoadingService.loadImage(from: .domain(domain),
                                                                         downsampleDescription: nil)
        var backgroundImage: UIImage?
        if let cachedProfile = DomainProfileInfoStorage.instance.getCachedDomainProfile(for: domain.name),
           let coverPath = cachedProfile.profile.profile.coverPath,
           let coverURL = URL(string: coverPath) {
            backgroundImage = await appContext.imageLoadingService.loadImage(from: .url(coverURL,
                                                                                        maxSize: Constants.downloadedImageMaxSize),
                                                                             downsampleDescription: nil)
        }
        
        let result = await UDRouter().showDomainProfileSignExternalWalletModule(in: view.topVisibleViewController(),
                                                                                domain: domain,
                                                                                imagesInfo: .init(backgroundImage: backgroundImage,
                                                                                                  avatarImage: avatarImage,
                                                                                                  avatarStyle: isOnChainAvatar ? .hexagon : .circle),
                                                                                externalWallet: walletInfo)
        
        return result
    }
    
    @MainActor
    func isProfileSignatureAvailable(for domain: DomainDisplayInfo, walletInfo: WalletDisplayInfo, in view: UIViewController) async -> Bool {
        guard !isAbleToLoadProfile(of: domain, walletInfo: walletInfo) else { return true }
     
        return await withSafeCheckedMainActorContinuation({ completion in
            Task {
                for await result in await askToSignExternalWalletProfileSignature(for: domain,
                                                                                  walletInfo: walletInfo,
                                                                                  in: view) {
                    switch result {
                    case .signMessage:
                        Task.detached {
                            do {
                                let domain = try await appContext.dataAggregatorService.getDomainWith(name: domain.name)
                                try await NetworkService().createAndStorePersistedProfileSignature(for: domain)
                                await view.dismiss(animated: true, completion: nil)
                                completion(true)
                            }  catch { }
                        }
                    case .walletImported:
                        await view.dismiss(animated: true)
                        completion(true)
                    case .close:
                        await view.dismiss(animated: true)
                        completion(false)
                    }
                }
                
                completion(false)
            }
        })
    }
    
}
