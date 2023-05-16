//
//  Debugger.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 10.06.2021.
//

import Foundation
import Bugsnag

// Light debugger
public struct Debugger {
    enum DebugTopic: String, CaseIterable {
        case None = ""

        case Transactions = "TXS"
        case Wallet = "WLT"
        case Domain = "DMN"
        case Error = "⛔️ERROR"
        case Payments = "PMNT"
        case Network = "WEB"
        case PNs = "PNs"
        case FileSystem = "FIL"
        case UniversalLink = "ULINK"
        case Navigation = "NAV"
        case Security = "SCRTY"
        case WalletConnect = "WC"
        case WalletConnectV2 = "WC_V2"
        case UI = "=UI="
        case Analytics = "Analytics"
        case Images = "IMG"
        case DataAggregation = "AGGR"
    }
    
    enum DebugTopicsSet {
        case all
        case debugDefault
        case debugWalletConnect
        case debugUI
        
        var allowedTopics: [DebugTopic] {
            switch self {
            case .all:
                return DebugTopic.allCases
            case .debugDefault:
                return topicsExcluding([.Network, .PNs, .Analytics, .Images, .FileSystem, .Navigation])
            case .debugWalletConnect:
                return [.Wallet, .Domain, .Error, .FileSystem, .WalletConnect, .WalletConnectV2]
            case .debugUI:
                return [.Error, .Navigation, .UI, .Images]
            }
        }
        
        private func topicsExcluding(_ excludedTopics: [DebugTopic]) -> [DebugTopic] {
            DebugTopic.allCases.filter({ !excludedTopics.contains($0) })
        }
    }
        
    static private var allowedTopics = DebugTopic.allCases
    
    static func setAllowedTopicsSet(_ topicsSet: DebugTopicsSet) {
        self.allowedTopics = topicsSet.allowedTopics
    }
    
    static func printInfo(topic: DebugTopic = .None, _ s: String) {
        //#if TESTFLIGHT
        if topic == .None {
            print ("🟩 \(s)")
        } else {
            if !allowedTopics.contains(topic) { return }
            print ("🟩 \(topic.rawValue): \(s)")
        }
        //#endif
    }
    
    static func printTimeSensitiveInfo(topic: DebugTopic, _ s: String, startDate: Date, timeout: TimeInterval) {
        let message = "\(String.itTook(from: startDate)) \(s)"
        let timeAfterStart = Date().timeIntervalSince(startDate)
        if timeAfterStart > timeout {
            printWarning(message)
        } else {
            printInfo(topic: topic, message)
        }
    }
    
    public static func printFailure(_ s: String, critical: Bool = false) {
        #if DEBUG
        if critical {
            fatalError("⛔️ CRITICAL ERROR: \(s)")
        } else { printInfo(topic: .Error, "🟨 \(s)") }
        #else
        let exception = NSException(name:NSExceptionName(rawValue: "\(critical ? "CRITICAL" : "NON-CRITICAL"): \(s)"),
                                    reason: "",
                                    userInfo: nil)
        Bugsnag.notify(exception)
        #endif
    }
    
    static func printWarning(_ s: String) {
        #if DEBUG
            print("🟨🔸 WARNING: \(s)")
        #else
        let exception = NSException(name:NSExceptionName(rawValue: "WARNING: \(s)"),
                                    reason: "",
                                    userInfo: nil)
        Bugsnag.notify(exception)
        #endif
    }
}
