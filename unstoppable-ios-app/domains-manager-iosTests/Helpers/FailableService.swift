//
//  FailableService.swift
//  domains-manager-iosTests
//
//  Created by Oleg Kuplin on 07.03.2024.
//

import Foundation

protocol FailableService {
    var shouldFail: Bool { get }
}

extension FailableService {
    func failIfNeeded() throws {
        if shouldFail {
            throw TestableGenericError.generic
        }
    }
}
