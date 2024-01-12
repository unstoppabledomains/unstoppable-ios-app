//
//  Debugger.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 10.06.2021.
//

import Foundation
import Bugsnag
import os.log

// Light debugger
public struct Debugger {
    private static let logger = Logger(subsystem: "com.unstoppabledomains",
                                       category: "debug")
    
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
        case Analytics = "Analtyics"
        case LocalNotification = "LN"
        case Images = "IMG"
        case DataAggregation = "AGGR"
        case CoreData = "CD"
        case WebSockets = "SOCKETS"
        case Messaging = "MS"
        case Debug = "DEBUG"
    }
    
    enum DebugTopicsSet {
        case all
        case debugDefault
        case debugWalletConnect
        case debugUI
        case debugNetwork
        case custom([DebugTopic])
        
        var allowedTopics: [DebugTopic] {
            switch self {
            case .all:
                return DebugTopic.allCases
            case .debugDefault:
                return topicsExcluding([.Network, .PNs, .Analytics, .Images, .FileSystem, .Navigation, .WebSockets])
            case .debugWalletConnect:
                return [.Wallet, .Domain, .Error, .FileSystem, .WalletConnect, .WalletConnectV2, .Debug]
            case .debugUI:
                return [.Error, .Navigation, .UI, .Images, .Debug]
            case .debugNetwork:
                return [.Network, .WebSockets, .Error, .Debug]
            case .custom(let topics):
                return topics
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
    
    static func isWebSocketsLogsEnabled() -> Bool {
        allowedTopics.contains(.WebSockets)
    }
    
    static func printInfo(topic: DebugTopic = .None, _ s: String) {
        //#if TESTFLIGHT
        if topic == .None {
            print ("🟩 \(s)")
        } else {
            if !allowedTopics.contains(topic) { return }
            logger.log("🟩 \(topic.rawValue, align: .left(columns: 10)): \(s)")
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
    
    public static func printFailure(_ s: String, critical: Bool = false, suppressBugSnag: Bool = false) {
        #if DEBUG
        if critical {
            fatalError("⛔️ CRITICAL ERROR: \(s)")
        } else {
            logger.critical("🟥 \(s)")
        }
        #else
        guard !suppressBugSnag else {
            return
        }
        let exception = NSException(name:NSExceptionName(rawValue: "\(critical ? "CRITICAL" : "NON-CRITICAL"): \(s)"),
                                    reason: "",
                                    userInfo: nil)
        Bugsnag.notify(exception)
        #endif
    }
    
    static func printWarning(_ s: String, suppressBugSnag: Bool = false) {
        #if DEBUG
        logger.warning("🟨🔸 WARNING: \(s)")
        #else
        guard !suppressBugSnag else {
            return
        }
        let exception = NSException(name:NSExceptionName(rawValue: "WARNING: \(s)"),
                                    reason: "",
                                    userInfo: nil)
        Bugsnag.notify(exception)
        #endif
    }
}
