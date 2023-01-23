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
        case Transactions = "TXS"
        case Wallet = "WLT"
        case Domain = "DMN"
        case Error = "⛔️ERROR"
        case Payments = "PMNT"
        case Network = "WEB"
        case PNs = "PNs"
        case FileSystem = "/FIL"
        case UniversalLink = "ULINK"
        case Navigation = "/NAV"
        case Security = "SCRTY"
        case WallectConnect = "WC"
        case WallectConnectV2 = "WC_V2"
        case None = ""
    }
    
    static let allowedTopics = DebugTopic.allCases.filter({ $0.rawValue.first != "/"})
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
