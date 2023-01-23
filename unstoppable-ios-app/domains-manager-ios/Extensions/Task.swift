//
//  Task.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 14.07.2022.
//

import Foundation

extension Task where Success == Never, Failure == Never {
    static func sleep(seconds duration: TimeInterval) async throws {
        let duration = UInt64(duration * 1_000_000_000)
        try await Task.sleep(nanoseconds: duration)
    }
}
