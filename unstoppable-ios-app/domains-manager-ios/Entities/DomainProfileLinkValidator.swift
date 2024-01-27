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
    
    static func getShowDomainProfileResultFor(url: URL) async -> ShowDomainProfileResult {
        guard let components = NSURLComponents(url: url, resolvingAgainstBaseURL: true),
              let domainName = getUDmeDomainName(in: components) else { return .none }
        
        return await getShowDomainProfileResultFor(domainName: domainName, params: components.queryItems)
    }
    
    static func getShowDomainProfileResultFor(domainName: String,
                                              params: [URLQueryItem]?) async -> ShowDomainProfileResult {
        
        var preRequestedAction: PreRequestedProfileAction?
        if let params,
           let badgeCode = params.findValue(forDeepLinkKey: DeepLinksParameterKey.openBadgeCode) {
            preRequestedAction = .showBadge(code: badgeCode)
        }
        
        let userDomains = await appContext.dataAggregatorService.getDomainsDisplayInfo()
        let wallets = appContext.walletsDataService.wallets
        if let domain = userDomains.first(where: { $0.name == domainName }),
           let wallet = wallets.first(where: { $0.udWallet.owns(domain: domain) }) {
            return .showUserDomainProfile(domain: domain,
                                          wallet: wallet,
                                          action: preRequestedAction)
        } else if let userDomainDisplayInfo = userDomains.first,
                  let viewingDomain = try? await appContext.dataAggregatorService.getDomainWith(name: userDomainDisplayInfo.name),
                  let globalRR = try? await NetworkService().fetchGlobalReverseResolution(for: domainName) {
            let publicDomainDisplayInfo = PublicDomainDisplayInfo(walletAddress: globalRR.address,
                                                                  name: domainName)
            return .showPublicDomainProfile(publicDomainDisplayInfo: publicDomainDisplayInfo,
                                            viewingDomain: viewingDomain,
                                            action: preRequestedAction)
        }
        
        return .none
    }
    
    enum ShowDomainProfileResult {
        case none
        case showUserDomainProfile(domain: DomainDisplayInfo, wallet: WalletEntity, action: PreRequestedProfileAction?)
        case showPublicDomainProfile(publicDomainDisplayInfo: PublicDomainDisplayInfo, viewingDomain: DomainItem, action: PreRequestedProfileAction?)
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
