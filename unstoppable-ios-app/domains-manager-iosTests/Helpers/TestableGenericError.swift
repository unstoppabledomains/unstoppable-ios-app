//
//  TestableGenericError.swift
//  domains-manager-iosTests
//
//  Created by Oleg Kuplin on 07.03.2024.
//

import Foundation

enum TestableGenericError: String, LocalizedError {
    case generic
    
    public var errorDescription: String? {
        return rawValue
    }
}
