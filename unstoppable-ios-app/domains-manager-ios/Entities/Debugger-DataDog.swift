//
//  Debugger-DataDog.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 26.06.2025.
//

import DatadogLogs
import DatadogCore

extension Debugger {
    private static var loggerDataDog: LoggerProtocol {
        
        Logs.enable()
        
        return Logger.create(
            with: Logger.Configuration(
                name: "UD",
                networkInfoEnabled: true,
                remoteLogThreshold: .info,
                consoleLogFormat: .shortWith(prefix: "[UD iOS Retro] ")
            )
        )
    }
    
    public static func logErrorToDataDog(_ s: String) {
        guard Datadog.isInitialized() else { return }
        loggerDataDog.error(s)
    }
    
    public static func logWarningToDataDog(_ s: String) {
        guard Datadog.isInitialized() else { return }
        loggerDataDog.warn(s)
    }
}
