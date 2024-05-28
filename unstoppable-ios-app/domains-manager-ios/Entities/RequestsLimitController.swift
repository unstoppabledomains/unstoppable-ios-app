//
//  RequestsLimitController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 24.05.2024.
//

import Foundation

actor RequestsLimitController {
    private var requestTimestamps: [Date] = []
    private let requestLimit: Int
    private let timeInterval: TimeInterval
    
    init(requestLimit: Int, timeInterval: TimeInterval) {
        self.requestLimit = requestLimit
        self.timeInterval = timeInterval
    }
    
    func acquirePermission() async {
        let now = Date()
        
        // Remove timestamps older than the specified time interval
        requestTimestamps = requestTimestamps.filter { now.timeIntervalSince($0) < timeInterval }
        
        if requestTimestamps.count >= requestLimit {
            let earliestRequest = requestTimestamps.first!
            let waitTime = timeInterval - now.timeIntervalSince(earliestRequest)
            await Task.sleep(seconds: waitTime)
            
            // Recheck and clean up the timestamps after waiting
            requestTimestamps = requestTimestamps.filter { now.timeIntervalSince($0) < timeInterval }
        }
        
        requestTimestamps.append(now)
    }
}
