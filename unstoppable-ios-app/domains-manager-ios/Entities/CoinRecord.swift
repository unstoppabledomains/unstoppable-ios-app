//
//  CoinRecord.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.05.2022.
//

import Foundation

struct CoinRecord: Hashable, Comparable, CustomStringConvertible, Codable {
    
    let ticker: String
    let version: String?
    let expandedTicker: String
    let regexPattern: String
    let isPrimaryChain: Bool
    let isDeprecated: Bool
    
    init(ticker: String, version: String?, expandedTicker: String, regexPattern: String?, isDeprecated: Bool) {
        self.ticker = ticker
        self.version = version
        self.expandedTicker = expandedTicker
        self.regexPattern = regexPattern ?? CoinRegexPattern.ETH.regex
        if let version = version {
            self.isPrimaryChain = CoinRecord.primaryChainsMap[ticker] == version
        } else {
            self.isPrimaryChain = true
        }
        self.isDeprecated = isDeprecated
    }
    
    init?(expandedTicker: String, regexPattern: String?, isDeprecated: Bool) {
        guard let ticker = Self.getShortTicker(from: expandedTicker) else { return nil }
        let version = Self.getVersion(from: expandedTicker)
        
        self.init(ticker: ticker,
                  version: version,
                  expandedTicker: expandedTicker,
                  regexPattern: regexPattern,
                  isDeprecated: isDeprecated)
    }
    
    static func < (lhs: CoinRecord, rhs: CoinRecord) -> Bool {
        lhs.expandedTicker < rhs.expandedTicker
    }
    
    var description: String {
        let versionSuffix = self.version == nil ? "" : " (\(self.version!))"
        return "\(self.ticker)\(versionSuffix)"
    }
    
    static func getShortTicker (from expandedTicker: String) -> String? {
        guard expandedTicker.prefix(6) == "crypto" else { return nil }
        let components = expandedTicker.split(separator: Character.dotSeparator)
        return String(components[1])
    }

    static func getVersion (from expandedTicker: String) -> String? {
        guard expandedTicker.prefix(6) == "crypto" else { return nil }
        let components = expandedTicker.split(separator: Character.dotSeparator)
        guard components.count == 5 else { return nil }

        return String(components[3])
    }
    
    func validate(_ proposedAddress: String) -> Bool {
        proposedAddress.isMatchingRegexPattern(regexPattern)
    }
    
    private static let primaryChainsMap: [String : String] = ["ELA" : "ELA",
                                                              "FTM" : "OPERA",
                                                              "FUSE" : "FUSE",
                                                              "MATIC" : "MATIC",
                                                              "UNI" : "ERC20",
                                                              "BUSD" : "BEP20",
                                                              "USDT" : "ERC20",
                                                              "WBTC" : "ERC20",
                                                              "AAVE" : "ERC20",
                                                              "SHIB" : "ERC20",
                                                              "CEL" : "ERC20",
                                                              "GALA" : "ERC20",
                                                              "B2M" : "ERC20",
                                                              "CAKE" : "BEP20",
                                                              "SAFEMOON" : "BEP20",
                                                              "TEL" : "ERC20",
                                                              "SUSHI" : "ERC20",
                                                              "TUSD" : "ERC20",
                                                              "HBTC" : "HRC20",
                                                              "SNX" : "ERC20",
                                                              "HOT" : "ERC20",
                                                              "NEXO" : "ERC20",
                                                              "MANA" : "ERC20",
                                                              "MDX" : "HRC20",
                                                              "LUSD" : "ERC20",
                                                              "GRT" : "ERC20",
                                                              "HUSD" : "ERC20", //
                                                              "CRV" : "ERC20",
                                                              "WRX" : "BEP2",
                                                              "LPT" : "ERC20",
                                                              "BAKE" : "BEP20",
                                                              "1INCH" : "ERC20",
                                                              "WOO" : "ERC20",
                                                              "OXY" : "SOLANA",
                                                              "REN" : "ERC20",
                                                              "RENBTC" : "ERC20",
                                                              "FEG" : "ERC20",
                                                              "MIR" : "ERC20",
                                                              "PAXG" : "ERC20",
                                                              "REEF" : "ERC20",
                                                              "BAND" : "ERC20",
                                                              "INJ" : "ERC20",
                                                              "SAND" : "ERC20",
                                                              "CTSI" : "ERC20",
                                                              "ANC" : "TERRA",
                                                              "IQ" : "ERC20",
                                                              "SUSD" : "ERC20",
                                                              "SRM" : "SOLANA",
                                                              "KEEP" : "ERC20",
                                                              "ALPHA" : "BEP20",
                                                              "DODO" : "BEP20",
                                                              "KNCL" : "ERC20",
                                                              "SXP" : "ERC20",
                                                              "UBT" : "ERC20",
                                                              "STORJ" : "ERC20",
                                                              "DPI" : "ERC20",
                                                              "DOG" : "ERC20",
                                                              "0ZK" : "0ZK",
                                                              "SWEAT" : "NEP-141",
                                                              "FET" : "FETCHAI",
                                                              "BNB" : "BEP20",
                                                              "USDC" : "ERC20",
                                                              "MCONTENT" : "BEP20",
                                                              "HI" : "ERC20"]
    
    private static let fullNamesMap: [String : String] = ["BTC" : "Bitcoin",
                                                          "ETH" : "Ethereum",
                                                          "ZIL" : "Zilliqa",
                                                          "LTC" : "Litecoin",
                                                          "XRP" : "Ripple",
                                                          "ETC" : "Ethereum Classic",
                                                          "EQL" : "Equal",
                                                          "LINK" : "Chainlink",
                                                          "USDC" : "USD Coin",
                                                          "BAT" : "Basic Attention Token",
                                                          "REP" : "Augur",
                                                          "ZRX" : "0x",
                                                          "DAI" : "Dai",
                                                          "BCH" : "Bitcoin Cash",
                                                          "XMR" : "Monero",
                                                          "DASH" : "Dash",
                                                          "NEO" : "Neo",
                                                          "DOGE" : "Dogecoin",
                                                          "ZEC" : "Zcash",
                                                          "ADA" : "Cardano",
                                                          "EOS" : "EOS",
                                                          "XLM" : "Stellar Lumens",
                                                          "BNB" : "Binance Coin",
                                                          "BTG" : "Bitcoin Gold",
                                                          "NANO" : "Nano",
                                                          "WAVES" : "Waves",
                                                          "KMD" : "Komodo",
                                                          "AE" : "Aeternity",
                                                          "RSK" : "RSK",
                                                          "WAN" : "Wanchain",
                                                          "STRAT" : "Stratis",
                                                          "UBQ" : "Ubiq",
                                                          "XTZ" : "Tezos",
                                                          "MIOTA" : "IOTA",
                                                          "VET" : "VeChain",
                                                          "QTUM" : "Qtum",
                                                          "ICX" : "ICON",
                                                          "DGB" : "DigiByte",
                                                          "XZC" : "Zcoin",
                                                          "BURST" : "Burst",
                                                          "DCR" : "Decred",
                                                          "XEM" : "NEM",
                                                          "LSK" : "Lisk",
                                                          "ATOM" : "Cosmos",
                                                          "ONG" : "Ontology Gas",
                                                          "ONT" : "Ontology",
                                                          "SMART" : "SmartCash",
                                                          "TPAY" : "TokenPay",
                                                          "GRS" : "GroestIcoin",
                                                          "BSV" : "Bitcoin SV",
                                                          "GAS" : "Gas",
                                                          "TRX" : "TRON",
                                                          "VTHO" : "VeThor Token",
                                                          "BCD" : "Bitcoin Diamond",
                                                          "BTT" : "BitTorrent",
                                                          "KIN" : "Kin",
                                                          "RVN" : "Ravencoin",
                                                          "ARK" : "Ark",
                                                          "XVG" : "Verge",
                                                          "ALGO" : "Algorand",
                                                          "NEBL" : "Neblio",
                                                          "BNTY" : "Bounty0x",
                                                          "ONE" : "Harmony",
                                                          "SWTH" : "Switcheo",
                                                          "CRO" : "Cronos",
                                                          "TWT" : "TWT",
                                                          "SIERRA" : "SIERRA",
                                                          "VSYS" : "VSYS",
                                                          "HIVE" : "HIVE",
                                                          "HT" : "Huobi Token",
                                                          "ENJ" : "Enjin Coin",
                                                          "YFI" : "yearn.finance",
                                                          "MTA" : "MTA",
                                                          "COMP" : "Compound",
                                                          "BAL" : "Balancer",
                                                          "AMPL" : "Ampleforth",
                                                          "LEND" : "AAVE (LEND)",
                                                          "USDT" : "Tether",
                                                          "FTM" : "Fantom",
                                                          "FUSE" : "Fuse Network",
                                                          "TLOS" : "Telos",
                                                          "AR" : "Arweave",
                                                          "XDC" : "XinFin",
                                                          "NIM" : "Nimiq",
                                                          "DOT" : "Polkadot",
                                                          "SOL" : "Solana",
                                                          "BUSD" : "Binance USD",
                                                          "SHIB" : "SHIBA INU",
                                                          "LUNA" : "Terra",
                                                          "CAKE" : "PancakeSwap",
                                                          "MANA" : "Decentraland",
                                                          "EGLD" : "Elrond",
                                                          "SAND" : "The Sandbox",
                                                          "HBAR" : "Hedera",
                                                          "WAXP" : "WAX",
                                                          "1INCH" : "1inch",
                                                          "SAFEMOON" : "SafeMoon",
                                                          "FIL" : "Filecoin",
                                                          "AXS" : "Axie Infinity",
                                                          "UNI" : "Uniswap",
                                                          "CEL" : "Celsius",
                                                          "ERG" : "Ergo",
                                                          "AMP" : "Amp",
                                                          "HNT": "Helium",
                                                          "KSM": "Kusama",
                                                          "LRC": "Loopring",
                                                          "ICP": "Internet Computer",
                                                          "KLV": "Klever",
                                                          "YLD": "Yield App",
                                                          "CELO" : "Celo",
                                                          "CSPR" : "Casper",
                                                          "KAVA" : "Kava",
                                                          "TUSD" : "TrueUSD",
                                                          "POLY" : "Polymath",
                                                          "NEXO" : "Nexo",
                                                          "FLOW" : "Flow",
                                                          "AVAX" : "Avalanche",
                                                          "NEAR" : "NEAR Protocol",
                                                          "THETA" : "THETA",
                                                          "TFUEL" : "Theta Fuel",
                                                          "MATIC" : "Polygon",
                                                          "CUSDT" : "Compound USDT",
                                                          "0ZK" : "Railgun"]
}

// MARK: - Open methods
extension CoinRecord {
    var name: String { ticker }
    var fullName: String? { CoinRecord.fullNamesMap[ticker] }
    var displayName: String { fullName ?? name }
}
