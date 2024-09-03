//
//  CoinRecord.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.05.2022.
//

import Foundation

struct CoinRecord: Hashable, CustomStringConvertible, Codable {
    
    let ticker: String
    let expandedTicker: String
    let network: String
    let fullName: String?
    let regexPatterns: [String]
    let isPrimaryChain: Bool
    
    init(ticker: String,
         version: String,
         expandedTicker: String,
         regexPattern: String?) {
        self.ticker = ticker
        self.network = version
        self.expandedTicker = expandedTicker
        
        if let regexPattern {
            self.regexPatterns = [regexPattern]
        } else {
            self.regexPatterns = [BlockchainType.Ethereum.regexPattern]
        }
        
        self.isPrimaryChain = version == ticker
        self.fullName = CoinRecord.fullNamesMap[ticker]
    }
    
    var description: String {
        return "\(self.ticker) (\(network))"
    }
    
    func validate(_ proposedAddress: String) -> Bool {
        regexPatterns.first(where: { proposedAddress.isMatchingRegexPattern($0) }) != nil
    }
    
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

extension CoinRecord: Comparable {
    static func < (lhs: CoinRecord, rhs: CoinRecord) -> Bool {
        lhs.expandedTicker < rhs.expandedTicker
    }
}

// MARK: - Open methods
extension CoinRecord {
    var name: String { ticker }
    var displayName: String { fullName ?? name }
}
