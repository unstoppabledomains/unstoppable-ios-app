//
//  DomainProfileGeneralData.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 10.10.2022.
//

import Foundation

@MainActor
protocol DomainProfileGeneralData {
    var domain: DomainDisplayInfo { get }
}
