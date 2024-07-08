//
//  WCCompatibleWallet.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 11.10.2021.
//

import Foundation
import UIKit

struct WCWalletsProvider {
    
    struct WalletRecord: Codable, Comparable, Hashable {
        static func < (lhs: WCWalletsProvider.WalletRecord, rhs: WCWalletsProvider.WalletRecord) -> Bool {
            return lhs.name < rhs.name
        }
        
        static func == (lhs: WCWalletsProvider.WalletRecord, rhs: WCWalletsProvider.WalletRecord) -> Bool {
            return lhs.name == rhs.name
        }
        
        func getNativeAppLink() -> String? {
            return self.mobile.native
        }
        
        func getUniversalAppLink() -> String? {
            guard self.mobile.universal != "" else {
                return self.mobile.native
            }
            return self.mobile.universal
        }

        let id: String
        let name: String
        let homepage: String?
        let appStoreLink: String?
        let mobile: MobileInfo
        let isV2Compatible: Bool
        
        var make: ExternalWalletMake? {
            ExternalWalletMake(rawValue: id)
        }
    }

    struct MobileInfo: Codable, Hashable {
        var native: String
        var universal: String
    }

    static let registryFilename = "wallets-registry" // https://explorer-api.walletconnect.com/v3/wallets?projectId=983234f8fb06d29cf4dd9d8ab60e9c3f
    static func fetchRegistry() -> [WalletRecord]? {
        let bundler = Bundle.main
        if let filePath = bundler.url(forResource: Self.registryFilename, withExtension: "json") {
            guard let data = try? Data(contentsOf: filePath),
                  let jsonReg = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                  let walletsRecs = jsonReg["listings"] as? [String: [String: Any]] else { return nil }
            
            var walletRecords: [WalletRecord] = []
            let wallets = Array(walletsRecs.values)
            
            for wallet in wallets {
                guard let id = wallet["id"] as? String,
                      let name = wallet["name"] as? String,
                      let homepage = wallet["homepage"] as? String?,
                      let appLinks = wallet["app"],
                      let storeLinks = appLinks as? [String: String?],
                      let appStoreLink = storeLinks["ios"],
                      let mobiles = wallet["mobile"],
                      let links = mobiles as? [String: String],
                      let native = links["native"],
                      let universal = links["universal"],
                      let sdks = wallet["sdks"] as? [String],
                      !native.isEmpty else {
                    continue
                }
                let fixedName = fixMathWalletName(name)
                let isV2compatible = sdks.contains("sign_v2")
                walletRecords.append(WalletRecord(id: id,
                                                  name: fixedName,
                                                  homepage: homepage,
                                                  appStoreLink: appStoreLink,
                                                  mobile: MobileInfo(native: native,
                                                                     universal: universal),
                                                  isV2Compatible: isV2compatible)
                )
            }
            return walletRecords.sorted(by: <)
        }
        return nil
    }
    
    private static func fixMathWalletName(_ name: String) -> String {
        switch name {
        case "MathWallet": return "MathWallet5"
        default: return name
        }
    }
    
    private static func printSchemas() {
        guard let registry = fetchRegistry() else { return }
        for wallet in registry {
            Debugger.printInfo("<string>\(wallet.mobile.native)</string>")
        }
    }
    
    @MainActor
    static func getDiscoverable(registry: [WalletRecord]) -> [WalletRecord] {
        return registry.filter({
            guard let nativeLink = $0.getNativeAppLink() else {
                return false
            }
            guard let url = URL(string: nativeLink) else {
                Debugger.printFailure("Can't create URL from native link: \(nativeLink)", critical: true)
                return false }
            let discoverable = UIApplication.shared.canOpenURL(url)
            return discoverable
        })
    }
    
    struct TwoWalletGroups {
        let recommended: [WalletRecord]
        let experimental: [WalletRecord]
        
        var totalCount: Int {
            recommended.count + experimental.count
        }
    }
    
    struct InstalledAndNotGroups {
        let installed: [WalletRecord]
        let notInstalled: [WalletRecord]
    }

    private static func breakIntoGroups(from walletsInstalled: [WalletRecord],
                                        for walletsGroup: WalletsGroup) -> TwoWalletGroups {
        var recs = [WalletRecord]()
        var exp = [WalletRecord]()
        let walletsList = walletsGroup.list
        
        for record in walletsInstalled {
            if let make = record.make {
                if walletsList.contains(make) {
                    recs.append(record)
                } else {
                    exp.append(record)
                }
            } else {
                Debugger.printFailure("No make for \(record.name)", critical: true)
            }
        }
        
        var recsSorted = [WalletRecord]()
        for wallet in walletsList {
            if let rec = recs.first(where: { $0.make == wallet }) {
                recsSorted.append(rec)
            }
        }
        
        return TwoWalletGroups(recommended: recsSorted,
                               experimental: exp.sorted(by: {$0 < $1}))
    }
    
    @MainActor
    static func getGroupedWcWallets(for walletsGroup: WalletsGroup) -> TwoWalletGroups {
        guard let allWcWallets = WCWalletsProvider.fetchRegistry() else {
            Debugger.printFailure("Failed to fetch a WC registry", critical: true)
            return TwoWalletGroups(recommended: [], experimental: [])
        }
        let walletsInstalled = getDiscoverable(registry: allWcWallets)
        
        let groupedWallets = breakIntoGroups(from: walletsInstalled, for: walletsGroup)
        return groupedWallets
    }
    
    @MainActor
    static func getGroupedInstalledAndNotWcWallets(for walletsGroup: WalletsGroup) -> InstalledAndNotGroups {
        guard let allWcWallets = WCWalletsProvider.fetchRegistry() else {
            Debugger.printFailure("Failed to fetch a WC registry", critical: true)
            return InstalledAndNotGroups(installed: [], notInstalled: [])
        }
        
        let discoverable = getDiscoverable(registry: allWcWallets)
        var installed: [WalletRecord] = []
        var notInstalled: [WalletRecord] = []
        
        for walletMake in walletsGroup.list {
            guard let record = allWcWallets.first(where: { $0.make == walletMake }) else { continue }

            if discoverable.first(where: { $0.make == walletMake }) == nil {
                notInstalled.append(record)
            } else {
                installed.append(record)
            }
        }
        
        let groupedWallets = InstalledAndNotGroups(installed: installed, notInstalled: notInstalled)
        return groupedWallets
    }
    
    @MainActor
    static func findBy(walletProxy: WCRegistryWalletProxy) -> WalletRecord? {
        
        guard let allWcWallets = WCWalletsProvider.fetchRegistry() else {
            Debugger.printFailure("Failed to fetch a WC registry", critical: true)
            return nil
        }
        let walletsInstalled = getDiscoverable(registry: allWcWallets)

        if walletProxy.needsLedgerSearchHack {
            return walletsInstalled.first(where: {$0.name.lowercased().contains("ledger")})
        }
        
        let host = walletProxy.host
        let hostSld = String(host.split(separator: Character.dotSeparator).dropLast().last ?? "")
        

        return walletsInstalled.first(where: {($0.homepage ?? "").contains(hostSld)})
    }
}

// MARK: - WalletsGroup
extension WCWalletsProvider {
    enum WalletsGroup {
        case supported
        
        var list: [ExternalWalletMake] {
            switch self {
            case .supported:
                #if DEBUG
                return [.MetaMask, .TrustWallet, .OKX, .Rainbow, .ledgerLive, .CryptoComDeFiWallet, .Zerion, .AlphaWallet, .Zelus, .MathWallet, .Omni, .ONTO, .KleverWallet, .Coinomi, .Coin98, .Argent, .Guarda, .Blockchain, .imToken, .Exodus, .Mew]
                #else
                return [.MetaMask, .TrustWallet, .OKX, .Rainbow, .ledgerLive, .CryptoComDeFiWallet, .Zerion, .AlphaWallet, .Zelus, .MathWallet, .Omni, .Mew]
                #endif
            }
        }
    }
}
