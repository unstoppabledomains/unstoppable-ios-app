//
//  DomainProfileLinkValidator.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 09.11.2023.
//

import Foundation

struct DomainProfileLinkValidator {
    static func getUDmeDomainName(in url: URL) -> String? {
        guard let components = NSURLComponents(url: url, resolvingAgainstBaseURL: true) else { return nil }
        
        return getUDmeDomainName(in: components)
    }
    
    static func getUDmeDomainName(in components: NSURLComponents) -> String? {
        guard let path = components.path,
              let host = components.host else { return nil }
        
        let pathComponents = path.components(separatedBy: "/")
        if Constants.udMeHosts.contains(host) {
            return validatedProfileName(pathComponents.last)
        } else if pathComponents.contains("d"),
                  pathComponents.count >= 3 {
            return validatedProfileName(pathComponents[2])
        }
        return nil
    }
    
    private static func validatedProfileName(_ profileName: String?) -> String? {
        if profileName?.isValidDomainName() == true {
            return profileName
        }
        return nil
    }
    
    static func getShowDomainProfilePresentationDetailsFor(url: URL) async -> ShowDomainProfilePresentationDetails? {
        guard let components = NSURLComponents(url: url, resolvingAgainstBaseURL: true),
              let domainName = getUDmeDomainName(in: components) else { return nil }
        
        return await getShowDomainProfilePresentationDetailsFor(domainName: domainName, params: components.queryItems)
    }
    
    static func getShowDomainProfilePresentationDetailsFor(domainName: String,
                                                           params: [URLQueryItem]?) async -> ShowDomainProfilePresentationDetails? {
        
        var preRequestedAction: PreRequestedProfileAction?
        if let params,
           let badgeCode = params.findValue(forDeepLinkKey: DeepLinksParameterKey.openBadgeCode) {
            preRequestedAction = .showBadge(code: badgeCode)
        }
        
        let wallets = appContext.walletsDataService.wallets
        if let wallet = wallets.findOwningDomain(domainName),
           let domain = wallet.domains.first(where: { $0.name == domainName }) {
            return .showUserDomainProfile(domain: domain,
                                          wallet: wallet,
                                          action: preRequestedAction)
        } else if let selectedWallet = appContext.walletsDataService.selectedWallet ?? appContext.walletsDataService.wallets.first,
                  let globalRR = try? await NetworkService().fetchGlobalReverseResolution(for: domainName) {
            let publicDomainDisplayInfo = PublicDomainDisplayInfo(walletAddress: globalRR.address,
                                                                  name: domainName)
            return .showPublicDomainProfile(publicDomainDisplayInfo: publicDomainDisplayInfo,
                                            wallet: selectedWallet,
                                            action: preRequestedAction)
        }
        
        return nil
    }
    
    enum ShowDomainProfilePresentationDetails {
        case showUserDomainProfile(domain: DomainDisplayInfo, wallet: WalletEntity, action: PreRequestedProfileAction?)
        case showPublicDomainProfile(publicDomainDisplayInfo: PublicDomainDisplayInfo, wallet: WalletEntity, action: PreRequestedProfileAction?)
    }
}

extension Array where Element == URLQueryItem {
    func findValue(for key: String) -> String? {
        first(where: { $0.name == key })?.value
    }
    
    func findValue<Key: RawRepresentable>(forDeepLinkKey key: Key) -> String? where Key.RawValue == String {
        first(where: { $0.name == key.rawValue })?.value
    }
}
